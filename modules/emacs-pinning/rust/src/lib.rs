//! Emacs Pinning System - Shared Library
//!
//! This module provides shared helper functions for the Emacs pinning system,
//! which allows pinning emacs-git to specific commits to avoid unwanted rebuilds
//! while still allowing controlled updates.
//!
//! The pinning system uses three cache files in ~/.cache:
//!   - emacs-git-pin: The pinned commit SHA
//!   - emacs-git-pin-hash: The SRI hash for the pinned commit
//!   - emacs-git-store-path: The Nix store path of the built configuredEmacs
//!
//! Core Workflow:
//!   1. User runs `emacs-pin` to pin current or specific commit
//!   2. System captures commit, hash, and already-built store path
//!   3. On next `ns` (build-switch), Nix reuses the stored path if pinned
//!   4. User can `emacs-unpin` to use latest overlay commit
//!   5. User can check status and compare with `emacs-pin-status` and `emacs-pin-diff`
//!
//! Dependencies:
//!   - Nix with flakes enabled
//!   - DARWIN_CONFIG_PATH environment variable set
//!   - nix-prefetch-github for fetching commit hashes
//!
//! Author: darwin-config repository (Rust port)
//! License: Same as darwin-config

use serde::Deserialize;
use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::Command;

// =============================================================================
// Constants and Configuration
// =============================================================================

/// Emoji constants for consistent output
pub const EMOJI_INFO: &str = "ℹ️";
pub const EMOJI_SUCCESS: &str = "✅";
pub const EMOJI_WARNING: &str = "⚠️";
pub const EMOJI_ERROR: &str = "❌";
pub const EMOJI_LIGHTBULB: &str = "💡";
pub const EMOJI_PIN: &str = "📌";
pub const EMOJI_UNLOCK: &str = "🔓";
pub const EMOJI_KEY: &str = "🔑";
pub const EMOJI_PACKAGE: &str = "📦";
pub const EMOJI_CHART: &str = "📈";
pub const EMOJI_LINK: &str = "🔗";
pub const EMOJI_SEARCH: &str = "🔍";

/// Get the cache directory path (~/.cache)
pub fn cache_dir() -> PathBuf {
    dirs::home_dir()
        .expect("Could not determine home directory")
        .join(".cache")
}

/// Get the pin file path (~/.cache/emacs-git-pin)
pub fn pin_file() -> PathBuf {
    cache_dir().join("emacs-git-pin")
}

/// Get the hash file path (~/.cache/emacs-git-pin-hash)
pub fn hash_file() -> PathBuf {
    cache_dir().join("emacs-git-pin-hash")
}

/// Get the store path file path (~/.cache/emacs-git-store-path)
pub fn store_path_file() -> PathBuf {
    cache_dir().join("emacs-git-store-path")
}

// =============================================================================
// Error Types
// =============================================================================

/// Custom error type for emacs-pin operations
#[derive(Debug)]
pub struct EmacsError {
    pub message: String,
}

impl EmacsError {
    pub fn new(message: impl Into<String>) -> Self {
        EmacsError {
            message: message.into(),
        }
    }
}

impl std::fmt::Display for EmacsError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl std::error::Error for EmacsError {}

pub type Result<T> = std::result::Result<T, EmacsError>;

// =============================================================================
// Configuration Path Management
// =============================================================================

/// Resolve and validate the DARWIN_CONFIG_PATH environment variable.
///
/// This path points to the darwin-config repository checkout and is required
/// for all Nix evaluation operations that read the flake.
///
/// # Returns
///
/// Validated path to darwin-config repository
///
/// # Errors
///
/// Returns an error if DARWIN_CONFIG_PATH is not set or invalid
///
/// # Example
///
/// ```no_run
/// use emacs_pin::resolve_config_path;
/// let config_path = resolve_config_path().expect("DARWIN_CONFIG_PATH not set");
/// println!("Config path: {}", config_path.display());
/// ```
pub fn resolve_config_path() -> Result<PathBuf> {
    let path_str = env::var("DARWIN_CONFIG_PATH").map_err(|_| {
        EmacsError::new(format!(
            "{} DARWIN_CONFIG_PATH is not set\n  Please run: nix run .#record-config-path",
            EMOJI_ERROR
        ))
    })?;

    let config_path = PathBuf::from(path_str);
    let flake_file = config_path.join("flake.nix");

    if !flake_file.exists() {
        return Err(EmacsError::new(format!(
            "{} DARWIN_CONFIG_PATH ({}) does not point to a darwin-config checkout\n  Expected to find: {}",
            EMOJI_ERROR,
            config_path.display(),
            flake_file.display()
        )));
    }

    Ok(config_path)
}

// =============================================================================
// Nix Evaluation Helpers
// =============================================================================

/// Extract the current emacs-git commit SHA from the flake's emacs-overlay input.
///
/// This uses Nix evaluation to read the commit that the emacs-overlay is currently
/// providing. This is the "latest" commit that would be built if not pinned.
///
/// # Arguments
///
/// * `config_path` - Path to darwin-config repository
/// * `system` - System architecture (default: aarch64-darwin)
///
/// # Returns
///
/// Commit SHA (full 40-character hash)
///
/// # Errors
///
/// Returns an error if Nix evaluation fails
///
/// # Note
///
/// Requires --impure because it reads from the flake in the working directory.
pub fn extract_current_emacs_commit(config_path: &Path, system: &str) -> Result<String> {
    let nix_expr = format!(
        r#"
        let
          flake = builtins.getFlake (toString ./.);
          em = flake.inputs.emacs-overlay.packages."{}".emacs-git;
        in em.src.rev
    "#,
        system
    );

    let output = Command::new("nix")
        .args(["eval", "--raw", "--impure", "--expr", &nix_expr])
        .current_dir(config_path)
        .output()
        .map_err(|e| EmacsError::new(format!("Failed to execute nix: {}", e)))?;

    if !output.status.success() {
        return Err(EmacsError::new(format!(
            "Nix evaluation failed: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

/// Extract the Nix store outPath of the emacs-git source derivation.
///
/// This is the path to the fetched Emacs source code in the Nix store.
/// We use this to compute the SRI hash.
///
/// # Arguments
///
/// * `config_path` - Path to darwin-config repository
/// * `system` - System architecture (default: aarch64-darwin)
///
/// # Returns
///
/// Nix store path to emacs source
///
/// # Errors
///
/// Returns an error if Nix evaluation fails
pub fn extract_current_emacs_src_outpath(config_path: &Path, system: &str) -> Result<String> {
    let nix_expr = format!(
        r#"
        let
          flake = builtins.getFlake (toString ./.);
          em = flake.inputs.emacs-overlay.packages."{}".emacs-git;
        in em.src.outPath
    "#,
        system
    );

    let output = Command::new("nix")
        .args(["eval", "--raw", "--impure", "--expr", &nix_expr])
        .current_dir(config_path)
        .output()
        .map_err(|e| EmacsError::new(format!("Failed to execute nix: {}", e)))?;

    if !output.status.success() {
        return Err(EmacsError::new(format!(
            "Nix evaluation failed: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

/// Extract the SRI hash of the current emacs-git source.
///
/// This extracts the hash directly from the source derivation's outputHash
/// attribute and converts it to SRI format. This approach doesn't require
/// the source to be built/fetched, avoiding issues with garbage-collected
/// store paths.
///
/// # Arguments
///
/// * `config_path` - Path to darwin-config repository
/// * `system` - System architecture (default: aarch64-darwin)
///
/// # Returns
///
/// SRI hash (format: sha256-base64...)
///
/// # Errors
///
/// Returns an error if hash extraction fails
pub fn extract_current_emacs_hash_sri(config_path: &Path, system: &str) -> Result<String> {
    let nix_expr = format!(
        r#"
        let
          flake = builtins.getFlake (toString ./.);
          em = flake.inputs.emacs-overlay.packages."{}".emacs-git;
        in em.src.outputHash
    "#,
        system
    );

    let output = Command::new("nix")
        .args(["eval", "--raw", "--impure", "--expr", &nix_expr])
        .current_dir(config_path)
        .output()
        .map_err(|e| EmacsError::new(format!("Failed to execute nix: {}", e)))?;

    if !output.status.success() {
        return Err(EmacsError::new(format!(
            "Nix evaluation failed: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }

    let base32_hash = String::from_utf8_lossy(&output.stdout).trim().to_string();

    // Convert base32 to SRI format
    sri_from_base32(&base32_hash)
}

/// Convert a base32 Nix hash to SRI format.
///
/// Older Nix tools (like nix-prefetch-github) may return base32 hashes.
/// This converts them to the SRI format that modern Nix expects.
///
/// # Arguments
///
/// * `base32_hash` - Base32-encoded hash
///
/// # Returns
///
/// SRI-encoded hash (sha256-base64...)
///
/// # Errors
///
/// Returns an error if conversion fails
///
/// # Example
///
/// ```no_run
/// use emacs_pin::sri_from_base32;
/// let sri = sri_from_base32("0abc123...").expect("Conversion failed");
/// println!("SRI: {}", sri);  // sha256-xyz789...
/// ```
pub fn sri_from_base32(base32_hash: &str) -> Result<String> {
    let output = Command::new("nix")
        .args(["hash", "to-sri", "--type", "sha256", base32_hash])
        .output()
        .map_err(|e| EmacsError::new(format!("Failed to execute nix: {}", e)))?;

    if !output.status.success() {
        return Err(EmacsError::new(format!(
            "Hash conversion failed: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

/// Extract the outPath of the configuredEmacs package from the flake.
///
/// The configuredEmacs is the final Emacs derivation with all packages (like vterm)
/// included. When pinned, this is the path that gets reused to avoid rebuilds.
///
/// The package name includes the hostname because the flake exports per-host packages.
///
/// # Arguments
///
/// * `config_path` - Path to darwin-config repository
/// * `hostname` - Current hostname (e.g., "predator")
/// * `system` - System architecture (default: aarch64-darwin)
///
/// # Returns
///
/// Nix store path to configuredEmacs
///
/// # Errors
///
/// Returns an error if Nix evaluation fails
///
/// # Note
///
/// This may fail if the package hasn't been built yet. That's expected
/// during initial pin setup - the path is captured after the first build.
pub fn extract_configured_emacs_outpath(
    config_path: &Path,
    hostname: &str,
    system: &str,
) -> Result<String> {
    let nix_expr = format!(
        r#"
        let
          flake = builtins.getFlake (toString ./.);
        in flake.packages."{}"."{}-configuredEmacs".outPath
    "#,
        system, hostname
    );

    let output = Command::new("nix")
        .args(["eval", "--raw", "--impure", "--expr", &nix_expr])
        .current_dir(config_path)
        .output()
        .map_err(|e| EmacsError::new(format!("Failed to execute nix: {}", e)))?;

    if !output.status.success() {
        return Err(EmacsError::new(format!(
            "Nix evaluation failed: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

// =============================================================================
// Cache File Operations
// =============================================================================

/// Safely read a cache file, handling missing files gracefully.
///
/// Cache files are simple text files containing a single line (commit hash,
/// SRI hash, or store path). This function reads and strips whitespace.
///
/// # Arguments
///
/// * `file_path` - Path to cache file
///
/// # Returns
///
/// File contents (stripped), or None if file doesn't exist
///
/// # Example
///
/// ```no_run
/// use emacs_pin::{read_cache_file, pin_file};
/// let commit = read_cache_file(&pin_file());
/// if let Some(commit) = commit {
///     println!("Pinned to: {}", commit);
/// }
/// ```
pub fn read_cache_file(file_path: &Path) -> Option<String> {
    match fs::read_to_string(file_path) {
        Ok(content) => Some(content.trim().to_string()),
        Err(_) => None,
    }
}

/// Atomically write content to a cache file.
///
/// This uses a write-and-rename pattern to ensure the file is either fully
/// written or not written at all (no partial writes on crashes).
///
/// # Arguments
///
/// * `file_path` - Path to cache file
/// * `content` - Content to write (will be stripped and newline-terminated)
///
/// # Errors
///
/// Returns an error if write fails
///
/// # Example
///
/// ```no_run
/// use emacs_pin::{write_cache_file, pin_file};
/// write_cache_file(&pin_file(), "abc123def456").expect("Write failed");
/// ```
pub fn write_cache_file(file_path: &Path, content: &str) -> Result<()> {
    // Ensure cache directory exists
    if let Some(parent) = file_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| EmacsError::new(format!("Failed to create cache directory: {}", e)))?;
    }

    // Atomic write: write to temp file, then rename
    let temp_file = file_path.with_extension("tmp");
    let mut file = fs::File::create(&temp_file)
        .map_err(|e| EmacsError::new(format!("Failed to create temp file: {}", e)))?;

    writeln!(file, "{}", content.trim())
        .map_err(|e| EmacsError::new(format!("Failed to write to temp file: {}", e)))?;

    fs::rename(&temp_file, file_path)
        .map_err(|e| EmacsError::new(format!("Failed to rename temp file: {}", e)))?;

    Ok(())
}

/// Resolve a path to its real location, following symlinks.
///
/// Nix store paths may be symlinks (especially for gc-rooted paths).
/// This resolves them to the actual store path.
///
/// # Arguments
///
/// * `path_str` - Path to resolve
///
/// # Returns
///
/// Resolved path, or original if resolution fails
///
/// # Example
///
/// ```no_run
/// use emacs_pin::resolve_store_path;
/// let real_path = resolve_store_path("/nix/store/abc-emacs");
/// println!("Real path: {}", real_path);
/// ```
pub fn resolve_store_path(path_str: &str) -> String {
    match fs::canonicalize(path_str) {
        Ok(path) => path.to_string_lossy().to_string(),
        Err(_) => path_str.to_string(),
    }
}

// =============================================================================
// Hash Fetching
// =============================================================================

/// JSON structure returned by nix-prefetch-github
#[derive(Deserialize)]
struct PrefetchResult {
    hash: Option<String>,
    sha256: Option<String>,
}

/// Fetch the SRI hash for a specific emacs-mirror commit.
///
/// This uses nix-prefetch-github to fetch (or compute from cache) the hash
/// for a given commit from the emacs-mirror/emacs repository.
///
/// The function tries two approaches:
/// 1. Extract the "hash" field (SRI format) from nix-prefetch-github JSON output
/// 2. If that's not available, extract "sha256" (base32) and convert to SRI
///
/// # Arguments
///
/// * `commit_sha` - Git commit SHA to fetch hash for
///
/// # Returns
///
/// SRI hash (sha256-base64...)
///
/// # Errors
///
/// Returns an error if hash fetch fails or commit doesn't exist
///
/// # Example
///
/// ```no_run
/// use emacs_pin::fetch_hash_for_commit;
/// let hash = fetch_hash_for_commit("abc123def456").expect("Fetch failed");
/// println!("Hash: {}", hash);
/// ```
pub fn fetch_hash_for_commit(commit_sha: &str) -> Result<String> {
    let output = Command::new("nix-prefetch-github")
        .args(["emacs-mirror", "emacs", "--rev", commit_sha])
        .output()
        .map_err(|e| EmacsError::new(format!("Failed to execute nix-prefetch-github: {}", e)))?;

    if !output.status.success() {
        return Err(EmacsError::new(format!(
            "nix-prefetch-github failed: {}",
            String::from_utf8_lossy(&output.stderr)
        )));
    }

    let result: PrefetchResult = serde_json::from_slice(&output.stdout)
        .map_err(|e| EmacsError::new(format!("Failed to parse JSON output: {}", e)))?;

    // Try to get SRI hash directly
    if let Some(hash) = result.hash {
        if !hash.is_empty() && hash != "null" {
            return Ok(hash);
        }
    }

    // Fallback: convert base32 sha256 to SRI
    if let Some(sha256) = result.sha256 {
        if !sha256.is_empty() && sha256 != "null" {
            return sri_from_base32(&sha256);
        }
    }

    Err(EmacsError::new(
        "nix-prefetch-github returned no valid hash",
    ))
}

// =============================================================================
// Commit Validation
// =============================================================================

/// Validate that a string looks like a Git commit SHA.
///
/// Accepts both short (7-character) and full (40-character) SHAs.
/// Only lowercase hexadecimal characters are allowed.
///
/// # Arguments
///
/// * `commit_sha` - String to validate
///
/// # Returns
///
/// True if format is valid
///
/// # Example
///
/// ```
/// use emacs_pin::validate_commit_format;
/// assert!(validate_commit_format("abc123d"));
/// assert!(!validate_commit_format("not-a-hash"));
/// ```
pub fn validate_commit_format(commit_sha: &str) -> bool {
    commit_sha.len() >= 7
        && commit_sha.len() <= 40
        && commit_sha.chars().all(|c| {
            c.is_ascii_digit() || matches!(c, 'a'..='f')
        })
}

// =============================================================================
// Hostname Detection
// =============================================================================

/// Get the current system hostname.
///
/// This is used to construct the package name for configuredEmacs,
/// which is exported as "{hostname}-configuredEmacs" in the flake.
///
/// # Returns
///
/// Hostname (short form, without domain)
///
/// # Example
///
/// ```no_run
/// use emacs_pin::get_hostname;
/// let hostname = get_hostname();
/// println!("Running on: {}", hostname);
/// ```
pub fn get_hostname() -> String {
    // Try hostname from system
    if let Ok(hostname) = hostname::get() {
        if let Ok(hostname_str) = hostname.into_string() {
            return hostname_str.split('.').next().unwrap_or("unknown").to_string();
        }
    }

    // Fallback to environment variable
    if let Ok(hostname) = env::var("HOSTNAME") {
        return hostname.split('.').next().unwrap_or("unknown").to_string();
    }

    // Last resort: use hostname command
    if let Ok(output) = Command::new("hostname").arg("-s").output() {
        if output.status.success() {
            return String::from_utf8_lossy(&output.stdout).trim().to_string();
        }
    }

    "unknown".to_string()
}

// =============================================================================
// System Detection
// =============================================================================

/// Detect the Nix system architecture string.
///
/// # Returns
///
/// Nix system string (e.g., "aarch64-darwin", "x86_64-darwin")
///
/// # Example
///
/// ```no_run
/// use emacs_pin::get_system_architecture;
/// let system = get_system_architecture();
/// println!("Building for: {}", system);
/// ```
pub fn get_system_architecture() -> String {
    match std::env::consts::ARCH {
        "aarch64" => "aarch64-darwin".to_string(),
        "x86_64" => "x86_64-darwin".to_string(),
        // Default to aarch64 for M1/M2/M3 Macs
        _ => "aarch64-darwin".to_string(),
    }
}

// =============================================================================
// Module Initialization
// =============================================================================

/// Ensure cache directory exists
pub fn ensure_cache_dir() -> io::Result<()> {
    fs::create_dir_all(cache_dir())
}
