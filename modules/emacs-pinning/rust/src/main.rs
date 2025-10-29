//! Emacs Pinning System - CLI Tool
//!
//! This tool manages pinning of emacs-git to specific commits to avoid
//! unwanted rebuilds while still allowing controlled updates.
//!
//! Available commands:
//!   - pin: Pin emacs-git to a specific commit or current overlay commit
//!   - unpin: Remove pinning and use latest from overlay
//!   - status: Show comprehensive pinning status
//!   - diff: Compare pinned commit with current overlay commit
//!
//! Author: darwin-config repository (Rust port)
//! License: Same as darwin-config

use clap::{Parser, Subcommand};
use emacs_pin::*;
use std::process;

// =============================================================================
// CLI Structure
// =============================================================================

/// Emacs Pinning System - Manage emacs-git commit pinning
#[derive(Parser)]
#[command(name = "emacs-pin")]
#[command(about = "Pin emacs-git to specific commits to avoid unwanted rebuilds", long_about = None)]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Pin emacs-git to a specific commit
    ///
    /// Without arguments: pins to current overlay commit
    /// With commit argument: pins to specific commit SHA
    Pin {
        /// Git commit SHA (7-40 hex characters). If omitted, pins to current overlay commit
        commit: Option<String>,
    },

    /// Remove pinning and use latest from overlay
    ///
    /// Removes all pinning state files, causing the next build to use
    /// the latest emacs-git commit from the emacs-overlay.
    Unpin,

    /// Show comprehensive pinning status
    ///
    /// Displays:
    /// - Current overlay commit (what's available)
    /// - Pinned commit (what you're locked to, if any)
    /// - Stored hash (SRI hash for the pinned commit)
    /// - Stored build path (Nix store path for reuse)
    /// - Current installed Emacs version
    Status,

    /// Compare pinned commit with current overlay commit
    ///
    /// Shows the difference between your pinned version and the latest
    /// available from the overlay, with a GitHub comparison URL.
    Diff,
}

// =============================================================================
// Pin Command Implementation
// =============================================================================

/// Pin Emacs to the current commit provided by emacs-overlay.
///
/// This is the most common use case: lock to whatever version is currently
/// in the flake, avoiding rebuilds when the overlay updates.
///
/// The function:
/// 1. Extracts current commit from flake
/// 2. Checks if already pinned to this commit
/// 3. Extracts hash for the commit
/// 4. Captures already-built configuredEmacs path
/// 5. Writes all cache files
/// 6. Prints status with guidance
///
/// # Returns
///
/// Exit code (0 for success, 1 for error)
fn pin_to_current_overlay() -> i32 {
    println!("{} No commit hash provided. Extracting from current emacs overlay...", EMOJI_LIGHTBULB);

    // Get config path and system info
    let config_path = match resolve_config_path() {
        Ok(path) => path,
        Err(e) => {
            eprintln!("{}", e);
            return 1;
        }
    };

    let system = get_system_architecture();

    // Extract current commit from overlay
    let commit = match extract_current_emacs_commit(&config_path, &system) {
        Ok(c) => {
            println!("{} Found current commit: {}", EMOJI_SUCCESS, c);
            c
        }
        Err(e) => {
            eprintln!("{} Could not extract current emacs-git commit from configuration", EMOJI_ERROR);
            eprintln!("   Error: {}", e);
            eprintln!("   Please specify a commit hash manually: emacs-pin pin <commit-hash>");
            eprintln!("   You can find commits at: https://github.com/emacs-mirror/emacs/commits/master");
            eprintln!("   Example: emacs-pin pin abc123def456");
            return 1;
        }
    };

    // Check if already pinned to this commit
    if let Some(existing_commit) = read_cache_file(&pin_file()) {
        if existing_commit == commit {
            println!("{} Already pinned to current overlay commit: {}", EMOJI_INFO, commit);
            println!("{} No rebuild necessary - configuration already matches pin", EMOJI_LIGHTBULB);
            return 0;
        }
    }

    // Extract hash for this commit
    println!("{} Extracting hash for current commit...", EMOJI_LIGHTBULB);
    let hash_sri = match extract_current_emacs_hash_sri(&config_path, &system) {
        Ok(h) => {
            println!("{} Found current hash: {}", EMOJI_SUCCESS, h);
            h
        }
        Err(e) => {
            eprintln!("{} Failed to extract hash: {}", EMOJI_ERROR, e);
            return 1;
        }
    };

    // Try to capture the current configuredEmacs outPath BEFORE changing pin state
    // This preserves the exact already-built store path, avoiding rebuilds later
    let current_out_path = {
        let hostname = get_hostname();
        match extract_configured_emacs_outpath(&config_path, &hostname, &system) {
            Ok(path) => {
                let resolved = resolve_store_path(&path);
                if std::path::Path::new(&resolved).exists() {
                    Some(resolved)
                } else {
                    None
                }
            }
            Err(_) => None,
        }
    };

    // Write cache files atomically
    if let Err(e) = write_cache_file(&pin_file(), &commit) {
        eprintln!("{} Failed to write pin file: {}", EMOJI_ERROR, e);
        return 1;
    }

    if let Err(e) = write_cache_file(&hash_file(), &hash_sri) {
        eprintln!("{} Failed to write hash file: {}", EMOJI_ERROR, e);
        return 1;
    }

    println!("{} Pinned emacs-git to current commit: {}", EMOJI_PIN, commit);
    println!("{} Stored hash (SRI): {}", EMOJI_KEY, hash_sri);

    // Save the already-built path if we captured it
    if let Some(path) = current_out_path {
        if let Err(e) = write_cache_file(&store_path_file(), &path) {
            eprintln!("{} Warning: Failed to save store path: {}", EMOJI_WARNING, e);
        } else {
            println!("{} Saved built path: {}", EMOJI_PACKAGE, path);
        }
    } else {
        println!("{} Could not resolve an existing configuredEmacs outPath at pin time (will build if needed)", EMOJI_INFO);
    }

    println!("{} Rebuild your configuration: nb && ns", EMOJI_LIGHTBULB);
    0
}

/// Pin Emacs to a specific commit SHA.
///
/// This allows pinning to a particular version, which is useful for:
/// - Rolling back to a known-good version
/// - Testing a specific commit
/// - Staying on a particular version longer than the overlay provides
///
/// # Arguments
///
/// * `commit` - Git commit SHA (7-40 characters)
///
/// # Returns
///
/// Exit code (0 for success, 1 for error)
fn pin_to_specific_commit(commit: &str) -> i32 {
    // Validate commit format
    if !validate_commit_format(commit) {
        eprintln!("{} Invalid commit hash format: {}", EMOJI_ERROR, commit);
        eprintln!("   Expected: 7-40 lowercase hexadecimal characters");
        eprintln!("   Example: abc123def456");
        return 1;
    }

    println!("{} Fetching hash for commit {}...", EMOJI_LIGHTBULB, commit);

    // Fetch hash from nix-prefetch-github
    let hash_sri = match fetch_hash_for_commit(commit) {
        Ok(h) => {
            println!("{} Found hash: {}", EMOJI_SUCCESS, h);
            h
        }
        Err(e) => {
            eprintln!("{} Failed to fetch hash for commit {}", EMOJI_ERROR, commit);
            eprintln!("   Error: {}", e);
            eprintln!("   Please check that the commit exists in the emacs-mirror/emacs repository.");
            return 1;
        }
    };

    // Try to capture current configuredEmacs path if it exists
    let current_out_path = match resolve_config_path() {
        Ok(config_path) => {
            let hostname = get_hostname();
            let system = get_system_architecture();
            match extract_configured_emacs_outpath(&config_path, &hostname, &system) {
                Ok(path) => {
                    let resolved = resolve_store_path(&path);
                    if std::path::Path::new(&resolved).exists() {
                        Some(resolved)
                    } else {
                        None
                    }
                }
                Err(_) => None,
            }
        }
        Err(_) => None,
    };

    // Write cache files
    if let Err(e) = write_cache_file(&pin_file(), commit) {
        eprintln!("{} Failed to write pin file: {}", EMOJI_ERROR, e);
        return 1;
    }

    if let Err(e) = write_cache_file(&hash_file(), &hash_sri) {
        eprintln!("{} Failed to write hash file: {}", EMOJI_ERROR, e);
        return 1;
    }

    println!("{} Pinned emacs-git to commit: {}", EMOJI_PIN, commit);
    println!("{} Stored hash (SRI): {}", EMOJI_KEY, hash_sri);

    // Save built path if available
    if let Some(path) = current_out_path {
        if let Err(e) = write_cache_file(&store_path_file(), &path) {
            eprintln!("{} Warning: Failed to save store path: {}", EMOJI_WARNING, e);
        } else {
            println!("{} Saved built path: {}", EMOJI_PACKAGE, path);
        }
    }

    println!("{} Rebuild your configuration: nb && ns", EMOJI_LIGHTBULB);
    0
}

// =============================================================================
// Unpin Command Implementation
// =============================================================================

/// Remove all pinning state files and print status.
///
/// # Returns
///
/// Exit code (always 0)
fn unpin() -> i32 {
    // Check if currently pinned
    let pinned_commit = read_cache_file(&pin_file());

    if pinned_commit.is_none() {
        println!("{} emacs-git is not currently pinned", EMOJI_INFO);
        return 0;
    }

    // Pinned - show what we're unpinning and remove files
    println!("{} Unpinning emacs-git from commit: {}", EMOJI_UNLOCK, pinned_commit.unwrap());

    // Remove all cache files
    let mut files_removed = Vec::new();
    for cache_file in [pin_file(), hash_file(), store_path_file()] {
        if cache_file.exists() {
            match std::fs::remove_file(&cache_file) {
                Ok(_) => {
                    if let Some(name) = cache_file.file_name() {
                        files_removed.push(name.to_string_lossy().to_string());
                    }
                }
                Err(e) => {
                    eprintln!("Warning: Failed to remove {:?}: {}", cache_file, e);
                }
            }
        }
    }

    if !files_removed.is_empty() {
        println!("   Removed: {}", files_removed.join(", "));
    }

    println!("{} Rebuild your configuration: nb && ns", EMOJI_LIGHTBULB);
    println!("   This will use the latest emacs-git commit from the overlay.");

    0
}

// =============================================================================
// Status Command Implementation
// =============================================================================

/// Display comprehensive status of the Emacs pinning system.
///
/// # Returns
///
/// Exit code (always 0)
fn status() -> i32 {
    // Get current overlay commit
    let current_overlay_commit = match resolve_config_path() {
        Ok(config_path) => {
            let system = get_system_architecture();
            match extract_current_emacs_commit(&config_path, &system) {
                Ok(commit) => {
                    println!("{} Current overlay emacs-git commit: {}", EMOJI_CHART, commit);
                    println!("{} View current: https://github.com/emacs-mirror/emacs/commit/{}", EMOJI_LINK, commit);
                    println!();
                    Some(commit)
                }
                Err(e) => {
                    println!("{} Could not extract current overlay commit: {}", EMOJI_WARNING, e);
                    println!();
                    None
                }
            }
        }
        Err(e) => {
            println!("{} Could not extract current overlay commit: {}", EMOJI_WARNING, e);
            println!();
            None
        }
    };

    // Check pin status
    let pinned_commit = read_cache_file(&pin_file());

    if pinned_commit.is_none() {
        // Not pinned
        println!("{} emacs-git is not pinned (using latest from overlay)", EMOJI_UNLOCK);
        if current_overlay_commit.is_some() {
            println!("   Run: emacs-pin pin (without arguments) to pin to current overlay commit");
        }
    } else {
        let pinned = pinned_commit.unwrap();
        // Pinned - show detailed status
        println!("{} emacs-git is pinned to commit: {}", EMOJI_PIN, pinned);
        println!("{} View pinned: https://github.com/emacs-mirror/emacs/commit/{}", EMOJI_LINK, pinned);

        // Compare with current overlay commit
        if let Some(ref current) = current_overlay_commit {
            if &pinned == current {
                println!("{} Pin matches current overlay commit", EMOJI_SUCCESS);
            } else {
                println!("{} Pin differs from current overlay commit", EMOJI_WARNING);
                println!("   Run: emacs-pin pin (without arguments) to pin to current overlay commit");
                println!("   Run: emacs-pin unpin to use latest overlay commit");
            }
        }

        // Show stored hash
        if let Some(stored_hash) = read_cache_file(&hash_file()) {
            println!("{} Stored hash (SRI): {}", EMOJI_KEY, stored_hash);
        } else {
            println!("{} Warning: No hash file found - pinning may not work correctly", EMOJI_WARNING);
            println!("   Run: emacs-pin pin {} to fix", pinned);
        }

        // Show stored build path
        if let Some(stored_path) = read_cache_file(&store_path_file()) {
            // Check if path still exists
            if std::path::Path::new(&stored_path).exists() {
                println!("{} Stored build path: {}", EMOJI_PACKAGE, stored_path);
            } else {
                println!("{} Stored build path not found (was GC'd): {}", EMOJI_WARNING, stored_path);
                println!("   Behavior: will build latest overlay commit and auto-pin to it after switch");
            }
        } else {
            println!("{} Stored build path not found (likely GC'd)", EMOJI_WARNING);
            println!("   Behavior: will build latest overlay commit and auto-pin to it after switch");
        }
    }

    // Show current Emacs version if available
    println!();
    if let Ok(output) = std::process::Command::new("which").arg("emacs").output() {
        if output.status.success() {
            if let Ok(version_output) = std::process::Command::new("emacs").arg("--version").output() {
                if version_output.status.success() {
                    let version_str = String::from_utf8_lossy(&version_output.stdout);
                    if let Some(first_line) = version_str.lines().next() {
                        println!("Current emacs version:");
                        println!("  {}", first_line);
                    }
                }
            }
        }
    }

    0
}

// =============================================================================
// Diff Command Implementation
// =============================================================================

/// Compare pinned commit with current overlay commit and display results.
///
/// # Returns
///
/// Exit code (0 for success, 1 for error)
fn diff() -> i32 {
    // Get current overlay commit
    let config_path = match resolve_config_path() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("{}", e);
            return 1;
        }
    };

    let system = get_system_architecture();
    let current_commit = match extract_current_emacs_commit(&config_path, &system) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("{} Could not extract current emacs-git commit from configuration", EMOJI_ERROR);
            eprintln!("   Error: {}", e);
            return 1;
        }
    };

    // Check if pinned
    let pinned_commit = read_cache_file(&pin_file());

    if pinned_commit.is_none() {
        // Not pinned - show current commit and suggest pinning
        println!("{} emacs-git is not pinned", EMOJI_UNLOCK);
        println!("{} Current overlay commit: {}", EMOJI_CHART, current_commit);
        println!();
        println!("{} To pin to current: emacs-pin pin (without arguments)", EMOJI_LIGHTBULB);
        return 0;
    }

    let pinned = pinned_commit.unwrap();

    // Pinned - compare commits
    if pinned == current_commit {
        // Pin matches current - we're up to date
        println!("{} Pinned commit matches current overlay commit", EMOJI_SUCCESS);
        println!("   Commit: {}", pinned);
        return 0;
    }

    // Pin differs from current - show comparison
    println!("{} Pinned commit: {}", EMOJI_PIN, pinned);
    println!("{} Current commit: {}", EMOJI_CHART, current_commit);
    println!();
    println!("{} Compare commits:", EMOJI_LINK);
    println!("   https://github.com/emacs-mirror/emacs/compare/{}...{}", pinned, current_commit);
    println!();
    println!("{} To update to current: emacs-pin pin (without arguments)", EMOJI_LIGHTBULB);
    println!("{} To unpin: emacs-pin unpin", EMOJI_LIGHTBULB);

    0
}

// =============================================================================
// Main Entry Point
// =============================================================================

fn main() {
    // Ensure cache directory exists
    if let Err(e) = ensure_cache_dir() {
        eprintln!("{} Failed to create cache directory: {}", EMOJI_ERROR, e);
        process::exit(1);
    }

    let cli = Cli::parse();

    let exit_code = match cli.command {
        Commands::Pin { commit } => match commit {
            None => pin_to_current_overlay(),
            Some(c) => pin_to_specific_commit(&c),
        },
        Commands::Unpin => unpin(),
        Commands::Status => status(),
        Commands::Diff => diff(),
    };

    process::exit(exit_code);
}
