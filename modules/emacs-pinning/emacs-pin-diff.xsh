#!/usr/bin/env xonsh
"""
Emacs Pin Diff - Show differences between pinned and current commits

This command compares the pinned Emacs commit (if any) with the current
commit provided by the emacs-overlay, helping you understand:
  - Whether you're on the latest version
  - How far behind your pin is from upstream
  - What changes are available if you update

Usage:
    emacs-pin-diff

Output scenarios:
  1. Not pinned: Shows current overlay commit and suggests pinning
  2. Pinned and matches current: Confirms you're on the latest
  3. Pinned and differs: Shows both commits with comparison URL

What it tells you:
  - Pinned commit: The version you're locked to (if pinned)
  - Current commit: The latest version from emacs-overlay
  - GitHub comparison URL: To review changes between the two

Use cases:
  - Check if there are updates available
  - Decide whether to update to the latest
  - Review what changed since you pinned
  - Verify your pin is working as expected

GitHub Comparison URL:
  The tool generates a URL like:
    https://github.com/emacs-mirror/emacs/compare/PINNED...CURRENT

  This shows all commits, changed files, and diffs between the two versions.
  Very useful for deciding whether to update.

Design Philosophy:
  This is a read-only, informational command that helps you make informed
  decisions about when to update. It never modifies any state.

See also: emacs-pin, emacs-unpin, emacs-pin-status

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
    Main entry point for emacs-pin-diff command.

    Compares pinned commit with current overlay commit and displays results.
    """
    try:
        # Get current overlay commit
        config_path = resolve_config_path()
        system = get_system_architecture()
        current_commit = extract_current_emacs_commit(config_path, system)

    except Exception as e:
        print(f"{EMOJI_ERROR} Could not extract current emacs-git commit from configuration", file=sys.stderr)
        print(f"   Error: {e}", file=sys.stderr)
        return 1

    # Check if pinned
    pinned_commit = read_cache_file(PIN_FILE)

    if not pinned_commit:
        # Not pinned - show current commit and suggest pinning
        print(f"{EMOJI_UNLOCK} emacs-git is not pinned")
        print(f"{EMOJI_CHART} Current overlay commit: {current_commit}")
        print()
        print(f"{EMOJI_LIGHTBULB} To pin to current: emacs-pin (without arguments)")
        return 0

    # Pinned - compare commits
    if pinned_commit == current_commit:
        # Pin matches current - we're up to date
        print(f"{EMOJI_SUCCESS} Pinned commit matches current overlay commit")
        print(f"   Commit: {pinned_commit}")
        return 0

    # Pin differs from current - show comparison
    print(f"{EMOJI_PIN} Pinned commit: {pinned_commit}")
    print(f"{EMOJI_CHART} Current commit: {current_commit}")
    print()
    print(f"{EMOJI_LINK} Compare commits:")
    print(f"   https://github.com/emacs-mirror/emacs/compare/{pinned_commit}...{current_commit}")
    print()
    print(f"{EMOJI_LIGHTBULB} To update to current: emacs-pin (without arguments)")
    print(f"{EMOJI_LIGHTBULB} To unpin: emacs-unpin")

    return 0


if __name__ == "__main__":
    sys.exit(main())
