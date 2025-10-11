#!/usr/bin/env xonsh
"""
Emacs Pin - Pin emacs-git to a specific commit

This command pins the Emacs installation to a specific commit from the
emacs-mirror/emacs repository, preventing unwanted rebuilds when the
emacs-overlay updates to a newer commit.

Usage:
    emacs-pin              # Pin to current overlay commit
    emacs-pin <commit>     # Pin to specific commit SHA

When pinning to the current overlay commit (no arguments):
  1. Extracts the commit SHA from the emacs-overlay flake input
  2. Checks if already pinned to that commit (early exit if so)
  3. Extracts the SRI hash for the commit
  4. Captures the already-built configuredEmacs store path (if available)
  5. Writes three cache files:
     - emacs-git-pin: The commit SHA
     - emacs-git-pin-hash: The SRI hash
     - emacs-git-store-path: The Nix store path (for reuse)

When pinning to a specific commit:
  1. Validates the commit format
  2. Fetches the hash using nix-prefetch-github
  3. Attempts to capture current configuredEmacs path if available
  4. Writes the cache files

After pinning, the next `ns` (build-switch) will:
  - Reuse the stored path if it exists and matches the pin (no rebuild)
  - Build the pinned commit if the stored path is missing (e.g., after GC)
  - Automatically re-pin to the newly built commit

Design Philosophy:
  The pinning system optimizes for developer workflow by:
  - Avoiding rebuilds when the overlay updates (if pinned and path exists)
  - Capturing already-built paths to maximize reuse
  - Auto-pinning after builds to lock in the new version
  - Making it easy to see what's pinned vs. what's latest

See also: emacs-pin-status, emacs-pin-diff, emacs-unpin

Author: darwin-config repository
License: Same as darwin-config
"""

import sys
import os
from pathlib import Path

# Import shared library by executing it in current namespace
# This makes all functions and constants available
lib_path = Path(__file__).parent / "emacs-pin-lib.xsh"
with open(lib_path) as f:
    exec(compile(f.read(), str(lib_path), 'exec'))


def pin_to_current_overlay():
    """
    Pin Emacs to the current commit provided by emacs-overlay.

    This is the most common use case: lock to whatever version is currently
    in the flake, avoiding rebuilds when the overlay updates.

    The function:
    1. Extracts current commit from flake
    2. Checks if already pinned to this commit
    3. Extracts hash for the commit
    4. Captures already-built configuredEmacs path
    5. Writes all cache files
    6. Prints status with guidance

    Returns:
        int: Exit code (0 for success, 1 for error)
    """
    print(f"{EMOJI_LIGHTBULB} No commit hash provided. Extracting from current emacs overlay...")

    try:
        # Get config path and system info
        config_path = resolve_config_path()
        system = get_system_architecture()

        # Extract current commit from overlay
        commit = extract_current_emacs_commit(config_path, system)
        print(f"{EMOJI_SUCCESS} Found current commit: {commit}")

        # Check if already pinned to this commit
        existing_commit = read_cache_file(PIN_FILE)
        if existing_commit == commit:
            print(f"{EMOJI_INFO} Already pinned to current overlay commit: {commit}")
            print(f"{EMOJI_LIGHTBULB} No rebuild necessary - configuration already matches pin")
            return 0

        # Extract hash for this commit
        print(f"{EMOJI_LIGHTBULB} Extracting hash for current commit...")
        hash_sri = extract_current_emacs_hash_sri(config_path, system)
        print(f"{EMOJI_SUCCESS} Found current hash: {hash_sri}")

        # Try to capture the current configuredEmacs outPath BEFORE changing pin state
        # This preserves the exact already-built store path, avoiding rebuilds later
        current_out_path = None
        try:
            hostname = get_hostname()
            current_out_path = extract_configured_emacs_outpath(config_path, hostname, system)

            # Resolve symlinks to get real store path
            if current_out_path:
                current_out_path = resolve_store_path(current_out_path)
        except Exception as e:
            # It's okay if this fails - might not be built yet
            pass

        # Write cache files atomically
        write_cache_file(PIN_FILE, commit)
        write_cache_file(HASH_FILE, hash_sri)

        print(f"{EMOJI_PIN} Pinned emacs-git to current commit: {commit}")
        print(f"{EMOJI_KEY} Stored hash (SRI): {hash_sri}")

        # Save the already-built path if we captured it
        if current_out_path and os.path.exists(current_out_path):
            write_cache_file(STORE_PATH_FILE, current_out_path)
            print(f"{EMOJI_PACKAGE} Saved built path: {current_out_path}")
        else:
            print(f"{EMOJI_INFO} Could not resolve an existing configuredEmacs outPath at pin time (will build if needed)")

        print(f"{EMOJI_LIGHTBULB} Rebuild your configuration: nb && ns")
        return 0

    except Exception as e:
        print(f"{EMOJI_ERROR} Could not extract current emacs-git commit from configuration", file=sys.stderr)
        print(f"   Error: {e}", file=sys.stderr)
        print(f"   Please specify a commit hash manually: emacs-pin <commit-hash>", file=sys.stderr)
        print(f"   You can find commits at: https://github.com/emacs-mirror/emacs/commits/master", file=sys.stderr)
        print(f"   Example: emacs-pin abc123def456", file=sys.stderr)
        return 1


def pin_to_specific_commit(commit):
    """
    Pin Emacs to a specific commit SHA.

    This allows pinning to a particular version, which is useful for:
    - Rolling back to a known-good version
    - Testing a specific commit
    - Staying on a particular version longer than the overlay provides

    Args:
        commit (str): Git commit SHA (7-40 characters)

    Returns:
        int: Exit code (0 for success, 1 for error)
    """
    # Validate commit format
    if not validate_commit_format(commit):
        print(f"{EMOJI_ERROR} Invalid commit hash format: {commit}", file=sys.stderr)
        print(f"   Expected: 7-40 lowercase hexadecimal characters", file=sys.stderr)
        print(f"   Example: abc123def456", file=sys.stderr)
        return 1

    print(f"{EMOJI_LIGHTBULB} Fetching hash for commit {commit}...")

    try:
        # Fetch hash from nix-prefetch-github
        hash_sri = fetch_hash_for_commit(commit)
        print(f"{EMOJI_SUCCESS} Found hash: {hash_sri}")

        # Try to capture current configuredEmacs path if it exists
        current_out_path = None
        try:
            config_path = resolve_config_path()
            hostname = get_hostname()
            system = get_system_architecture()
            current_out_path = extract_configured_emacs_outpath(config_path, hostname, system)

            if current_out_path:
                current_out_path = resolve_store_path(current_out_path)
        except Exception:
            # It's okay if this fails
            pass

        # Write cache files
        write_cache_file(PIN_FILE, commit)
        write_cache_file(HASH_FILE, hash_sri)

        print(f"{EMOJI_PIN} Pinned emacs-git to commit: {commit}")
        print(f"{EMOJI_KEY} Stored hash (SRI): {hash_sri}")

        # Save built path if available
        if current_out_path and os.path.exists(current_out_path):
            write_cache_file(STORE_PATH_FILE, current_out_path)
            print(f"{EMOJI_PACKAGE} Saved built path: {current_out_path}")

        print(f"{EMOJI_LIGHTBULB} Rebuild your configuration: nb && ns")
        return 0

    except Exception as e:
        print(f"{EMOJI_ERROR} Failed to fetch hash for commit {commit}", file=sys.stderr)
        print(f"   Error: {e}", file=sys.stderr)
        print(f"   Please check that the commit exists in the emacs-mirror/emacs repository.", file=sys.stderr)
        return 1


def main():
    """
    Main entry point for emacs-pin command.

    Parses command-line arguments and dispatches to the appropriate function.
    """
    # Ensure cache directory exists
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    # Parse arguments
    args = sys.argv[1:]

    if len(args) == 0:
        # No arguments: pin to current overlay commit
        return pin_to_current_overlay()
    elif len(args) == 1:
        # One argument: pin to specific commit
        commit = args[0]
        return pin_to_specific_commit(commit)
    else:
        # Too many arguments
        print(f"{EMOJI_ERROR} Too many arguments", file=sys.stderr)
        print(f"", file=sys.stderr)
        print(f"Usage:", file=sys.stderr)
        print(f"  emacs-pin              Pin to current overlay commit", file=sys.stderr)
        print(f"  emacs-pin <commit>     Pin to specific commit", file=sys.stderr)
        print(f"", file=sys.stderr)
        print(f"Examples:", file=sys.stderr)
        print(f"  emacs-pin                    # Pin to current", file=sys.stderr)
        print(f"  emacs-pin abc123def456       # Pin to specific commit", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
