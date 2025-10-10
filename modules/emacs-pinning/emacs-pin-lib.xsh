#!/usr/bin/env xonsh
"""
Emacs Pinning System - Shared Library

This module provides shared helper functions for the Emacs pinning system,
which allows pinning emacs-git to specific commits to avoid unwanted rebuilds
while still allowing controlled updates.

The pinning system uses three cache files in ~/.cache:
  - emacs-git-pin: The pinned commit SHA
  - emacs-git-pin-hash: The SRI hash for the pinned commit
  - emacs-git-store-path: The Nix store path of the built configuredEmacs

Core Workflow:
  1. User runs `emacs-pin` to pin current or specific commit
  2. System captures commit, hash, and already-built store path
  3. On next `ns` (build-switch), Nix reuses the stored path if pinned
  4. User can `emacs-unpin` to use latest overlay commit
  5. User can check status and compare with `emacs-pin-status` and `emacs-pin-diff`

Dependencies:
  - Nix with flakes enabled
  - DARWIN_CONFIG_PATH environment variable set
  - nix-prefetch-github for fetching commit hashes

Author: darwin-config repository
License: Same as darwin-config
"""

import sys
import os
from pathlib import Path
import subprocess
import json


# =============================================================================
# Constants and Configuration
# =============================================================================

CACHE_DIR = Path.home() / ".cache"
PIN_FILE = CACHE_DIR / "emacs-git-pin"
HASH_FILE = CACHE_DIR / "emacs-git-pin-hash"
STORE_PATH_FILE = CACHE_DIR / "emacs-git-store-path"

# Emoji constants for consistent output
EMOJI_INFO = "ℹ️"
EMOJI_SUCCESS = "✅"
EMOJI_WARNING = "⚠️"
EMOJI_ERROR = "❌"
EMOJI_LIGHTBULB = "💡"
EMOJI_PIN = "📌"
EMOJI_UNLOCK = "🔓"
EMOJI_KEY = "🔑"
EMOJI_PACKAGE = "📦"
EMOJI_CHART = "📈"
EMOJI_LINK = "🔗"
EMOJI_SEARCH = "🔍"


# =============================================================================
# Configuration Path Management
# =============================================================================

def resolve_config_path():
    """
    Resolve and validate the DARWIN_CONFIG_PATH environment variable.

    This path points to the darwin-config repository checkout and is required
    for all Nix evaluation operations that read the flake.

    Returns:
        Path: Validated path to darwin-config repository

    Raises:
        SystemExit: If DARWIN_CONFIG_PATH is not set or invalid

    Example:
        >>> config_path = resolve_config_path()
        >>> print(config_path / "flake.nix")
    """
    # Access environment variable - use os.environ for raw string access
    # (xonsh's __xonsh__.env may return lists or EnvPath objects)
    path_str = os.environ.get('DARWIN_CONFIG_PATH', '')

    if not path_str:
        print(f"{EMOJI_ERROR} DARWIN_CONFIG_PATH is not set", file=sys.stderr)
        print("  Please run: nix run .#record-config-path", file=sys.stderr)
        sys.exit(1)

    config_path = Path(path_str)
    flake_file = config_path / "flake.nix"

    if not flake_file.exists():
        print(f"{EMOJI_ERROR} DARWIN_CONFIG_PATH ({config_path}) does not point to a darwin-config checkout", file=sys.stderr)
        print(f"  Expected to find: {flake_file}", file=sys.stderr)
        sys.exit(1)

    return config_path


# =============================================================================
# Nix Evaluation Helpers
# =============================================================================

def extract_current_emacs_commit(config_path, system="aarch64-darwin"):
    """
    Extract the current emacs-git commit SHA from the flake's emacs-overlay input.

    This uses Nix evaluation to read the commit that the emacs-overlay is currently
    providing. This is the "latest" commit that would be built if not pinned.

    Args:
        config_path (Path): Path to darwin-config repository
        system (str): System architecture (default: aarch64-darwin)

    Returns:
        str: Commit SHA (full 40-character hash)

    Raises:
        RuntimeError: If Nix evaluation fails

    Note:
        Requires --impure because it reads from the flake in the working directory.
    """
    nix_expr = f'''
        let
          flake = builtins.getFlake (toString ./.);
          em = flake.inputs.emacs-overlay.packages."{system}".emacs-git;
        in em.src.rev
    '''

    try:
        # Use subprocess to run nix eval with the expression
        result = subprocess.run(
            ['nix', 'eval', '--raw', '--impure', '--expr', nix_expr],
            cwd=str(config_path),
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(f"Nix evaluation failed: {result.stderr}")
        return result.stdout.strip()
    except Exception as e:
        raise RuntimeError(f"Failed to extract emacs commit: {e}")


def extract_current_emacs_src_outpath(config_path, system="aarch64-darwin"):
    """
    Extract the Nix store outPath of the emacs-git source derivation.

    This is the path to the fetched Emacs source code in the Nix store.
    We use this to compute the SRI hash.

    Args:
        config_path (Path): Path to darwin-config repository
        system (str): System architecture (default: aarch64-darwin)

    Returns:
        str: Nix store path to emacs source

    Raises:
        RuntimeError: If Nix evaluation fails
    """
    nix_expr = f'''
        let
          flake = builtins.getFlake (toString ./.);
          em = flake.inputs.emacs-overlay.packages."{system}".emacs-git;
        in em.src.outPath
    '''

    try:
        # Use subprocess to run nix eval with the expression
        result = subprocess.run(
            ['nix', 'eval', '--raw', '--impure', '--expr', nix_expr],
            cwd=str(config_path),
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(f"Nix evaluation failed: {result.stderr}")
        return result.stdout.strip()
    except Exception as e:
        raise RuntimeError(f"Failed to extract emacs src outPath: {e}")


def extract_current_emacs_hash_sri(config_path):
    """
    Compute the SRI hash of the current emacs-git source.

    This uses `nix hash path` to compute the SHA256 hash of the source
    in SRI (Subresource Integrity) format, which is what Nix's fetchFromGitHub
    expects in modern configurations.

    Args:
        config_path (Path): Path to darwin-config repository

    Returns:
        str: SRI hash (format: sha256-base64...)

    Raises:
        RuntimeError: If hash computation fails
    """
    try:
        src_path = extract_current_emacs_src_outpath(config_path)
        result = subprocess.run(
            ['nix', 'hash', 'path', '--type', 'sha256', src_path],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(f"Hash computation failed: {result.stderr}")
        return result.stdout.strip()
    except Exception as e:
        raise RuntimeError(f"Failed to compute emacs hash: {e}")


def sri_from_base32(base32_hash):
    """
    Convert a base32 Nix hash to SRI format.

    Older Nix tools (like nix-prefetch-github) may return base32 hashes.
    This converts them to the SRI format that modern Nix expects.

    Args:
        base32_hash (str): Base32-encoded hash

    Returns:
        str: SRI-encoded hash (sha256-base64...)

    Raises:
        RuntimeError: If conversion fails

    Example:
        >>> sri = sri_from_base32("0abc123...")
        >>> print(sri)  # sha256-xyz789...
    """
    try:
        result = subprocess.run(
            ['nix', 'hash', 'to-sri', '--type', 'sha256', base32_hash],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(f"Hash conversion failed: {result.stderr}")
        return result.stdout.strip()
    except Exception as e:
        raise RuntimeError(f"Failed to convert hash to SRI: {e}")


def extract_configured_emacs_outpath(config_path, hostname, system="aarch64-darwin"):
    """
    Extract the outPath of the configuredEmacs package from the flake.

    The configuredEmacs is the final Emacs derivation with all packages (like vterm)
    included. When pinned, this is the path that gets reused to avoid rebuilds.

    The package name includes the hostname because the flake exports per-host packages.

    Args:
        config_path (Path): Path to darwin-config repository
        hostname (str): Current hostname (e.g., "predator")
        system (str): System architecture (default: aarch64-darwin)

    Returns:
        str: Nix store path to configuredEmacs

    Raises:
        RuntimeError: If Nix evaluation fails

    Note:
        This may fail if the package hasn't been built yet. That's expected
        during initial pin setup - the path is captured after the first build.
    """
    nix_expr = f'''
        let
          flake = builtins.getFlake (toString ./.);
        in flake.packages."{system}"."{hostname}-configuredEmacs".outPath
    '''

    try:
        # Use subprocess to run nix eval with the expression
        result = subprocess.run(
            ['nix', 'eval', '--raw', '--impure', '--expr', nix_expr],
            cwd=str(config_path),
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(f"Nix evaluation failed: {result.stderr}")
        return result.stdout.strip()
    except Exception as e:
        raise RuntimeError(f"Failed to extract configuredEmacs outPath: {e}")


# =============================================================================
# Cache File Operations
# =============================================================================

def read_cache_file(file_path):
    """
    Safely read a cache file, handling missing files gracefully.

    Cache files are simple text files containing a single line (commit hash,
    SRI hash, or store path). This function reads and strips whitespace.

    Args:
        file_path (Path): Path to cache file

    Returns:
        str or None: File contents (stripped), or None if file doesn't exist

    Example:
        >>> commit = read_cache_file(PIN_FILE)
        >>> if commit:
        ...     print(f"Pinned to: {commit}")
    """
    try:
        if not file_path.exists():
            return None
        return file_path.read_text().strip()
    except Exception as e:
        print(f"{EMOJI_WARNING} Failed to read {file_path}: {e}", file=sys.stderr)
        return None


def write_cache_file(file_path, content):
    """
    Atomically write content to a cache file.

    This uses a write-and-rename pattern to ensure the file is either fully
    written or not written at all (no partial writes on crashes).

    Args:
        file_path (Path): Path to cache file
        content (str): Content to write (will be stripped and newline-terminated)

    Raises:
        RuntimeError: If write fails

    Example:
        >>> write_cache_file(PIN_FILE, commit_sha)
    """
    try:
        # Ensure cache directory exists
        CACHE_DIR.mkdir(parents=True, exist_ok=True)

        # Atomic write: write to temp file, then rename
        temp_file = file_path.with_suffix('.tmp')
        temp_file.write_text(content.strip() + '\n')
        temp_file.rename(file_path)
    except Exception as e:
        raise RuntimeError(f"Failed to write {file_path}: {e}")


def resolve_store_path(path_str):
    """
    Resolve a path to its real location, following symlinks.

    Nix store paths may be symlinks (especially for gc-rooted paths).
    This resolves them to the actual store path.

    Args:
        path_str (str): Path to resolve

    Returns:
        str: Resolved path, or original if resolution fails

    Example:
        >>> real_path = resolve_store_path("/nix/store/abc-emacs")
    """
    try:
        path = Path(path_str)
        if path.is_symlink():
            return str(path.resolve())
        return path_str
    except Exception:
        return path_str


# =============================================================================
# Hash Fetching
# =============================================================================

def fetch_hash_for_commit(commit_sha):
    """
    Fetch the SRI hash for a specific emacs-mirror commit.

    This uses nix-prefetch-github to fetch (or compute from cache) the hash
    for a given commit from the emacs-mirror/emacs repository.

    The function tries two approaches:
    1. Extract the "hash" field (SRI format) from nix-prefetch-github JSON output
    2. If that's not available, extract "sha256" (base32) and convert to SRI

    Args:
        commit_sha (str): Git commit SHA to fetch hash for

    Returns:
        str: SRI hash (sha256-base64...)

    Raises:
        RuntimeError: If hash fetch fails or commit doesn't exist

    Example:
        >>> hash_sri = fetch_hash_for_commit("abc123def456...")
    """
    try:
        # Use nix-prefetch-github to fetch the hash
        result = subprocess.run(
            ['nix-prefetch-github', 'emacs-mirror', 'emacs', '--rev', commit_sha],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(f"nix-prefetch-github failed: {result.stderr}")

        # Parse JSON output
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            raise RuntimeError("Failed to parse nix-prefetch-github output as JSON")

        # Try to get SRI hash directly
        if "hash" in data and data["hash"] and data["hash"] != "null":
            return data["hash"]

        # Fallback: convert base32 sha256 to SRI
        if "sha256" in data and data["sha256"] and data["sha256"] != "null":
            return sri_from_base32(data["sha256"])

        raise RuntimeError("nix-prefetch-github returned no valid hash")

    except Exception as e:
        raise RuntimeError(f"Failed to fetch hash for commit {commit_sha}: {e}")


# =============================================================================
# Commit Validation
# =============================================================================

def validate_commit_format(commit_sha):
    """
    Validate that a string looks like a Git commit SHA.

    Accepts both short (7-character) and full (40-character) SHAs.

    Args:
        commit_sha (str): String to validate

    Returns:
        bool: True if format is valid

    Example:
        >>> validate_commit_format("abc123d")  # True
        >>> validate_commit_format("not-a-hash")  # False
    """
    import re
    # Match 7-40 lowercase hex characters
    return bool(re.match(r'^[a-f0-9]{7,40}$', commit_sha))


# =============================================================================
# Hostname Detection
# =============================================================================

def get_hostname():
    """
    Get the current system hostname.

    This is used to construct the package name for configuredEmacs,
    which is exported as "{hostname}-configuredEmacs" in the flake.

    Returns:
        str: Hostname (short form, without domain)

    Example:
        >>> hostname = get_hostname()
        >>> print(f"Running on: {hostname}")
    """
    try:
        import socket
        return socket.gethostname().split('.')[0]
    except Exception:
        # Fallback to environment or subprocess
        if 'HOSTNAME' in os.environ:
            return os.environ['HOSTNAME'].split('.')[0]
        try:
            result = subprocess.run(
                ['hostname', '-s'],
                capture_output=True,
                text=True
            )
            return result.stdout.strip()
        except Exception:
            return "unknown"


# =============================================================================
# System Detection
# =============================================================================

def get_system_architecture():
    """
    Detect the Nix system architecture string.

    Returns:
        str: Nix system string (e.g., "aarch64-darwin", "x86_64-darwin")

    Example:
        >>> system = get_system_architecture()
        >>> print(f"Building for: {system}")
    """
    import platform
    machine = platform.machine()
    if machine == "arm64":
        return "aarch64-darwin"
    elif machine == "x86_64":
        return "x86_64-darwin"
    else:
        # Default to aarch64 for M1/M2/M3 Macs
        return "aarch64-darwin"


# =============================================================================
# Module Initialization
# =============================================================================

# Ensure cache directory exists when module is imported
CACHE_DIR.mkdir(parents=True, exist_ok=True)


# =============================================================================
# Testing Support
# =============================================================================

if __name__ == "__main__":
    """
    Module self-test: verify all helper functions work.

    Run with: xonsh emacs-pin-lib.xsh
    """
    print("=" * 80)
    print("Emacs Pin Library Self-Test")
    print("=" * 80)

    try:
        # Test config path resolution
        print(f"\n{EMOJI_SEARCH} Testing config path resolution...")
        config_path = resolve_config_path()
        print(f"{EMOJI_SUCCESS} Config path: {config_path}")

        # Test hostname detection
        print(f"\n{EMOJI_SEARCH} Testing hostname detection...")
        hostname = get_hostname()
        print(f"{EMOJI_SUCCESS} Hostname: {hostname}")

        # Test system detection
        print(f"\n{EMOJI_SEARCH} Testing system architecture...")
        system = get_system_architecture()
        print(f"{EMOJI_SUCCESS} System: {system}")

        # Test commit extraction
        print(f"\n{EMOJI_SEARCH} Testing current emacs commit extraction...")
        commit = extract_current_emacs_commit(config_path, system)
        print(f"{EMOJI_SUCCESS} Current commit: {commit}")

        # Test commit validation
        print(f"\n{EMOJI_SEARCH} Testing commit validation...")
        assert validate_commit_format(commit), "Current commit should be valid"
        assert not validate_commit_format("invalid"), "Invalid string should fail"
        print(f"{EMOJI_SUCCESS} Validation works correctly")

        # Test cache file operations
        print(f"\n{EMOJI_SEARCH} Testing cache file operations...")
        test_file = CACHE_DIR / "test-file"
        write_cache_file(test_file, "test-content")
        content = read_cache_file(test_file)
        assert content == "test-content", "Content should match"
        test_file.unlink()
        print(f"{EMOJI_SUCCESS} Cache operations work correctly")

        print(f"\n{EMOJI_SUCCESS} All tests passed!")

    except Exception as e:
        print(f"\n{EMOJI_ERROR} Test failed: {e}", file=sys.stderr)
        sys.exit(1)
