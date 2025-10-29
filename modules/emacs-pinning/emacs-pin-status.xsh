#!/usr/bin/env xonsh
"""
Emacs Pin Status - Show comprehensive Emacs pinning status

This command provides a complete overview of your Emacs pinning state,
including:
  - Current overlay commit (what's available)
  - Pinned commit (what you're locked to, if any)
  - Stored hash (SRI hash for the pinned commit)
  - Stored build path (Nix store path for reuse)
  - Current installed Emacs version

Usage:
    emacs-pin-status

Output when pinned:
  📈 Current overlay emacs-git commit: abc123...
  🔗 View current: https://github.com/emacs-mirror/emacs/commit/abc123...

  📌 emacs-git is pinned to commit: def456...
  🔗 View pinned: https://github.com/emacs-mirror/emacs/commit/def456...
  ✅ Pin matches current overlay commit
    OR
  ⚠️  Pin differs from current overlay commit
     Run: emacs-pin (without arguments) to pin to current overlay commit
     Run: emacs-unpin to use latest overlay commit

  🔑 Stored hash (SRI): sha256-xyz789...
  📦 Stored build path: /nix/store/abc-emacs-git-with-packages

  Current emacs version:
  GNU Emacs 31.0.50 (build 1, aarch64-apple-darwin...)

Output when not pinned:
  📈 Current overlay emacs-git commit: abc123...
  🔗 View current: https://github.com/emacs-mirror/emacs/commit/abc123...

  🔓 emacs-git is not pinned (using latest from overlay)
     Run: emacs-pin (without arguments) to pin to current overlay commit

Understanding the output:
  - Current overlay commit: Latest from emacs-overlay (updates with flake)
  - Pinned commit: Your locked version (prevents rebuilds on overlay updates)
  - Stored hash: Used by Nix to fetch the exact source
  - Stored build path: If present, `ns` reuses this (no rebuild)

What "stored build path not found" means:
  The pin files exist, but the built Emacs was garbage collected.
  The next `ns` will build the latest overlay commit (not the pinned commit)
  and auto-pin to it. This is intentional behavior to avoid building
  outdated versions that aren't available in substituters.

Design Philosophy:
  This command is the primary way to understand your Emacs pinning state.
  Use it frequently to verify:
    - You're pinned when you think you are
    - The stored path is present (no rebuild needed)
    - Your pin matches or differs from the latest

See also: emacs-pin, emacs-unpin, emacs-pin-diff

Author: darwin-config repository
License: Same as darwin-config
"""

import sys
import os
import subprocess
from pathlib import Path

# Import shared library by executing it in current namespace
lib_path = Path(__file__).parent / "emacs-pin-lib.xsh"
with open(lib_path) as f:
    exec(compile(f.read(), str(lib_path), 'exec'))


def main():
    """
    Main entry point for emacs-pin-status command.

    Displays comprehensive status of the Emacs pinning system.
    """
    # Get current overlay commit
    current_overlay_commit = None
    try:
        config_path = resolve_config_path()
        system = get_system_architecture()
        current_overlay_commit = extract_current_emacs_commit(config_path, system)
        print(f"{EMOJI_CHART} Current overlay emacs-git commit: {current_overlay_commit}")
        print(f"{EMOJI_LINK} View current: https://github.com/emacs-mirror/emacs/commit/{current_overlay_commit}")
        print()
    except Exception as e:
        print(f"{EMOJI_WARNING} Could not extract current overlay commit: {e}")
        print()

    # Check pin status
    pinned_commit = read_cache_file(PIN_FILE)

    if not pinned_commit:
        # Not pinned
        print(f"{EMOJI_UNLOCK} emacs-git is not pinned (using latest from overlay)")
        if current_overlay_commit:
            print(f"   Run: emacs-pin (without arguments) to pin to current overlay commit")
    else:
        # Pinned - show detailed status
        print(f"{EMOJI_PIN} emacs-git is pinned to commit: {pinned_commit}")
        print(f"{EMOJI_LINK} View pinned: https://github.com/emacs-mirror/emacs/commit/{pinned_commit}")

        # Compare with current overlay commit
        if current_overlay_commit:
            if pinned_commit == current_overlay_commit:
                print(f"{EMOJI_SUCCESS} Pin matches current overlay commit")
            else:
                print(f"{EMOJI_WARNING} Pin differs from current overlay commit")
                print(f"   Run: emacs-pin (without arguments) to pin to current overlay commit")
                print(f"   Run: emacs-unpin to use latest overlay commit")

        # Show stored hash
        stored_hash = read_cache_file(HASH_FILE)
        if stored_hash:
            print(f"{EMOJI_KEY} Stored hash (SRI): {stored_hash}")
        else:
            print(f"{EMOJI_WARNING} Warning: No hash file found - pinning may not work correctly")
            print(f"   Run: emacs-pin {pinned_commit} to fix")

        # Show stored build path
        stored_path = read_cache_file(STORE_PATH_FILE)
        if stored_path:
            # Check if path still exists
            if os.path.exists(stored_path):
                print(f"{EMOJI_PACKAGE} Stored build path: {stored_path}")
            else:
                print(f"{EMOJI_WARNING} Stored build path not found (was GC'd): {stored_path}")
                print(f"   Behavior: will build latest overlay commit and auto-pin to it after switch")
        else:
            print(f"{EMOJI_WARNING} Stored build path not found (likely GC'd)")
            print(f"   Behavior: will build latest overlay commit and auto-pin to it after switch")

    # Show current Emacs version if available
    print()
    try:
        result = subprocess.run(
            ['which', 'emacs'],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print("Current emacs version:")
            version_result = subprocess.run(
                ['emacs', '--version'],
                capture_output=True,
                text=True
            )
            if version_result.returncode == 0:
                first_line = version_result.stdout.strip().split('\n')[0]
                print(f"  {first_line}")
    except Exception:
        pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
