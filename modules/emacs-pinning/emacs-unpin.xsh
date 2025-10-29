#!/usr/bin/env xonsh
"""
Emacs Unpin - Remove Emacs version pinning

This command removes all pinning state, causing the next `ns` (build-switch)
to use the latest emacs-git commit from the emacs-overlay.

Usage:
    emacs-unpin

What it does:
  1. Checks if currently pinned (reads emacs-git-pin file)
  2. Displays the commit that's being unpinned
  3. Removes all three cache files:
     - emacs-git-pin: The pinned commit
     - emacs-git-pin-hash: The SRI hash
     - emacs-git-store-path: The stored build path
  4. Prints guidance on next steps

After unpinning:
  - The next `ns` will build the latest commit from emacs-overlay
  - The build will be auto-pinned after a successful switch
  - You can re-pin at any time with `emacs-pin`

Use cases for unpinning:
  - You want to update to the latest Emacs from the overlay
  - You're testing if a newer version fixes an issue
  - You want to return to tracking upstream automatically

Design Philosophy:
  Unpinning is a safe operation that just removes local state files.
  The worst case is that the next build takes longer (if Emacs needs
  to be rebuilt), but it will auto-pin after the build completes.

See also: emacs-pin, emacs-pin-status, emacs-pin-diff

Author: darwin-config repository
License: Same as darwin-config
"""

import sys
import os
from pathlib import Path

# Import shared library by executing it in current namespace
lib_path = Path(__file__).parent / "emacs-pin-lib.xsh"
with open(lib_path) as f:
    exec(compile(f.read(), str(lib_path), 'exec'))


def main():
    """
    Main entry point for emacs-unpin command.

    Removes all pinning state files and prints status.
    """
    # Check if currently pinned
    pinned_commit = read_cache_file(PIN_FILE)

    if not pinned_commit:
        print(f"{EMOJI_INFO} emacs-git is not currently pinned")
        return 0

    # Pinned - show what we're unpinning and remove files
    print(f"{EMOJI_UNLOCK} Unpinning emacs-git from commit: {pinned_commit}")

    # Remove all cache files
    files_removed = []
    for cache_file in [PIN_FILE, HASH_FILE, STORE_PATH_FILE]:
        if cache_file.exists():
            try:
                cache_file.unlink()
                files_removed.append(cache_file.name)
            except Exception as e:
                print(f"Warning: Failed to remove {cache_file}: {e}", file=sys.stderr)

    if files_removed:
        print(f"   Removed: {', '.join(files_removed)}")

    print(f"{EMOJI_LIGHTBULB} Rebuild your configuration: nb && ns")
    print(f"   This will use the latest emacs-git commit from the overlay.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
