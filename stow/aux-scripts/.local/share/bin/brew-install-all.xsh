#!/bin/sh
# Xonsh bootstrap for shells that ignore xonsh shebangs.
''':' 2>/dev/null
if [ -n "${XONSH_EXE:-}" ] && [ -x "${XONSH_EXE}" ]; then
    exec "${XONSH_EXE}" --no-rc "$0" "$@"
fi
if [ -n "${XONSH_BIN:-}" ] && [ -x "${XONSH_BIN}" ]; then
    exec "${XONSH_BIN}" --no-rc "$0" "$@"
fi
PIXIXONSH="${HOME}/darwin-config/python-env/.pixi/envs/default/bin/xonsh"
if [ -x "${PIXIXONSH}" ]; then
    exec "${PIXIXONSH}" --no-rc "$0" "$@"
fi
if command -v xonsh >/dev/null 2>&1; then
    exec xonsh --no-rc "$0" "$@"
fi
PIXIMANIFEST="${HOME}/darwin-config/python-env/pixi.toml"
if command -v pixi >/dev/null 2>&1 && [ -f "${PIXIMANIFEST}" ]; then
    exec pixi run --manifest-path "${PIXIMANIFEST}" xonsh --no-rc "$0" "$@"
fi
echo "brew-install-all.xsh: unable to locate xonsh (set XONSH_EXE or install pixi env)" >&2
exit 127
'''
#
# brew-install-all.xsh - Declarative Homebrew package management (Xonsh version)
#
# This script manages your Homebrew installation declaratively. Define your
# desired packages in the lists below, and the script will ensure your
# system matches that state.
#
# USAGE:
#   brew-install-all.xsh [OPTIONS]
#
# OPTIONS:
#   --help, -h      Show this help message and exit
#   --dry-run       Preview changes without executing them
#   --sync          Install missing packages AND remove unlisted ones
#   --cascade       Like --sync, but force-remove packages with dependents
#   --list          List all packages defined in this script
#   --diff          Show difference between defined and installed packages
#
# EXAMPLES:
#   # Install all missing packages (safe, won't remove anything)
#   brew-install-all.xsh
#
#   # Preview what would be installed
#   brew-install-all.xsh --dry-run
#
#   # Sync system to match this file (install missing, remove unlisted)
#   brew-install-all.xsh --sync
#
#   # Preview sync changes before applying
#   brew-install-all.xsh --sync --dry-run
#
#   # Force sync even if packages have dependents
#   brew-install-all.xsh --cascade
#
#   # List all packages defined in this script
#   brew-install-all.xsh --list
#
#   # Show what's different between this file and your system
#   brew-install-all.xsh --diff
#
# WORKFLOW:
#   1. Edit this script to add/remove packages from the lists
#   2. Run 'brew-install-all.xsh --diff' to see what would change
#   3. Run 'brew-install-all.xsh --sync --dry-run' to preview
#   4. Run 'brew-install-all.xsh --sync' to apply changes
#
# ADDING PACKAGES:
#   - Regular formulas: Add to FORMULAS list
#   - Formulas with flags: Add to SPECIAL_FORMULAS as ("name", "--flags")
#   - GUI apps (casks): Add to CASKS list
#   - Third-party repos: Add to TAPS list
#
# Generated from: brew list --installed-on-request (2025-01-25)
# Location: ~/darwin-config/stow/aux-scripts/.local/share/bin/brew-install-all.xsh

import sys
import os
import subprocess
from pathlib import Path
from argparse import ArgumentParser

# =============================================================================
# PACKAGE DEFINITIONS
# =============================================================================
# Based on: brew list --installed-on-request (2025-01-25)
# Dependencies are handled automatically by Homebrew.

# Taps (third-party repositories)
TAPS = [
    "coursier/formulas",
    "homebrew-ffmpeg/ffmpeg",  # For ffmpeg-full
    "jetbrains/utils",
    "jimeh/emacs-builds",      # For emacs-app-nightly
    "nikitabobko/tap",
    "oven-sh/bun",
    "quantonganh/tap",
]

# Standard formulas (explicitly requested, not dependencies)
# Source: brew list --installed-on-request
FORMULAS = [
    # Development tools & languages
    "autoconf",
    "bash-language-server",
    "boot-clj",
    "bun",
    "cargo-binstall",
    "cljfmt",
    "clojure",
    "clojure-lsp",
    "cmake",
    "cmake-language-server",
    "coursier",
    "gcc",
    "go",
    "jdtls",
    "jdtls-wrapper",
    "kotlin",
    "kotlin-language-server",
    "kotlin-lsp",
    "lazygit",
    "libtool",
    "make",
    "ncurses",
    "ninja",
    "opam",
    "pixi",
    "protobuf",
    "tree-sitter-cli",
    "volta",
    "xcode-build-server",
    "z3",
    "zig",

    # CLI tools
    "aria2",
    "atuin",
    "bat",
    "bat-extras",
    "difftastic",
    "dockutil",
    "eza",
    "gemini-cli",
    "gh",
    "git-filter-repo",
    "git-lfs",
    "gnu-tar",
    "grep",
    "jq",
    "markdown-oxide",
    "markdownlint-cli2",
    "marksman",
    "mas",
    "pass",
    "pinentry-mac",
    "pngpaste",
    "prettier",
    "pueue",
    "sevenzip",
    "stow",
    "swig",
    "tombi",
    "trash-cli",
    "turso",
    "yq",
    "zip",

    # Media & documents
    "ffmpeg-full",
    "fontforge",
    "ghostscript",
    "imagemagick",
    "multimarkdown",
    "resvg",

    # Libraries (explicitly needed for builds)
    "boost",
    "libgccjit",
    "libsql",
    "libvterm",
    # "lld",
    # "llvm",

    # Containers
    "podman",
    "podman-tui",
]

# Formulas with special flags: list of (formula, flags) tuples
# Use full tap/name for custom taps
# Example: ("llvm", "--HEAD") for bleeding-edge builds
SPECIAL_FORMULAS = [
    # Add formulas that need special install flags here
    # ("formula-name", "--HEAD"),
    ("local/llvm/llvm", "--HEAD"),
    ("lld", "--HEAD"),
]

# Casks (GUI applications)
# Source: brew list --cask
CASKS = [
    # Productivity & communication
    "1password-cli",
    "1password@nightly",
    "chatgpt",
    "chatgpt-atlas",
    "claude",
    "claude-code",
    "codex",
    "comet",
    "discord",
    "dropbox",
    "element",
    "espanso",
    "fastmail",
    "microsoft-teams",
    "obsidian",
    "raycast",
    "slack",
    "snagit",
    "super-productivity",
    "whatsapp",
    "zoom",

    # Development
    "aerospace",
    "cljstyle",
    "dotnet-sdk",
    "emacs-app-nightly",
    "ghostty@tip",
    "jetbrains-toolbox",
    "kitty",
    "ollama-app",
    "orbstack",
    "podman-desktop",
    "visual-studio-code@insiders",
    "wezterm@nightly",

    # Browsers
    "google-chrome",
    "safari-technology-preview",

    # Media
    "spotify",
    "tidal",

    # System utilities
    "nordvpn",

    # Fonts
    "font-jetbrains-mono-nerd-font",

    # Other
    "mactex",
]

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def run_cmd(cmd: list[str], dry_run: bool = False, capture: bool = False) -> subprocess.CompletedProcess | None:
    """Run a command, or print it in dry-run mode."""
    if dry_run:
        print(f"    {' '.join(cmd)}")
        return None
    try:
        if capture:
            return subprocess.run(cmd, capture_output=True, text=True)
        else:
            return subprocess.run(cmd)
    except Exception as e:
        print(f"    Error: {e}")
        return None

def get_formula_basename(formula: str) -> str:
    """Get base name from formula (e.g., 'oscarvarto/jank/llvm-head' -> 'llvm-head')."""
    return formula.split("/")[-1]

def normalize_formula_name(formula: str) -> str:
    """Normalize formula name for comparison (handles tap paths and basenames)."""
    return formula.split("/")[-1]

def get_all_wanted_formulas() -> tuple[list[str], set[str]]:
    """Build complete list of wanted formula names.

    Returns:
        tuple: (full_names for installation, normalized_names for comparison)
    """
    full_names = list(FORMULAS)
    normalized = set(normalize_formula_name(f) for f in FORMULAS)

    for formula, _ in SPECIAL_FORMULAS:
        full_names.append(formula)
        normalized.add(normalize_formula_name(formula))

    return full_names, normalized

def get_special_formula_basenames() -> set[str]:
    """Get basenames of formulas in SPECIAL_FORMULAS (to skip in regular install)."""
    return set(get_formula_basename(formula) for formula, _ in SPECIAL_FORMULAS)

def get_installed_formulas() -> list[str]:
    """Get list of all installed formulas (not just leaves)."""
    # Use 'brew list --formula' instead of 'brew leaves' for consistency
    # with is_formula_installed() checks
    result = subprocess.run(["brew", "list", "--formula"], capture_output=True, text=True)
    if result.returncode == 0:
        return [f.strip() for f in result.stdout.strip().split("\n") if f.strip()]
    return []

def get_installed_formula_leaves() -> list[str]:
    """Get list of installed formula leaves (for sync removal decisions)."""
    result = subprocess.run(["brew", "leaves"], capture_output=True, text=True)
    if result.returncode == 0:
        return [f.strip() for f in result.stdout.strip().split("\n") if f.strip()]
    return []

def get_installed_casks() -> list[str]:
    """Get list of installed casks."""
    result = subprocess.run(["brew", "list", "--cask"], capture_output=True, text=True)
    if result.returncode == 0:
        return [c.strip() for c in result.stdout.strip().split("\n") if c.strip()]
    return []

def get_tapped_repos() -> list[str]:
    """Get list of tapped repositories."""
    result = subprocess.run(["brew", "tap"], capture_output=True, text=True)
    if result.returncode == 0:
        return [t.strip() for t in result.stdout.strip().split("\n") if t.strip()]
    return []

def is_formula_installed(formula: str) -> bool:
    """Check if a formula is installed."""
    result = subprocess.run(["brew", "list", "--formula", formula],
                          capture_output=True, text=True)
    return result.returncode == 0

def is_cask_installed(cask: str) -> bool:
    """Check if a cask is installed."""
    result = subprocess.run(["brew", "list", "--cask", cask],
                          capture_output=True, text=True)
    return result.returncode == 0

# =============================================================================
# COMMAND HANDLERS
# =============================================================================

def show_help():
    """Display help message."""
    help_text = """
brew-install-all.xsh - Declarative Homebrew package management (Xonsh version)

USAGE:
  brew-install-all.xsh [OPTIONS]

OPTIONS:
  --help, -h      Show this help message and exit
  --dry-run       Preview changes without executing them
  --sync          Install missing packages AND remove unlisted ones
  --cascade       Like --sync, but force-remove packages with dependents
  --list          List all packages defined in this script
  --diff          Show difference between defined and installed packages

EXAMPLES:
  # Install all missing packages (safe, won't remove anything)
  brew-install-all.xsh

  # Preview what would be installed
  brew-install-all.xsh --dry-run

  # Sync system to match this file (install missing, remove unlisted)
  brew-install-all.xsh --sync

  # Preview sync changes before applying
  brew-install-all.xsh --sync --dry-run

  # Force sync even if packages have dependents
  brew-install-all.xsh --cascade

  # List all packages defined in this script
  brew-install-all.xsh --list

  # Show what's different between this file and your system
  brew-install-all.xsh --diff

WORKFLOW:
  1. Edit this script to add/remove packages from the lists
  2. Run 'brew-install-all.xsh --diff' to see what would change
  3. Run 'brew-install-all.xsh --sync --dry-run' to preview
  4. Run 'brew-install-all.xsh --sync' to apply changes

ADDING PACKAGES:
  - Regular formulas: Add to FORMULAS list
  - Formulas with flags: Add to SPECIAL_FORMULAS as ("name", "--flags")
  - GUI apps (casks): Add to CASKS list
  - Third-party repos: Add to TAPS list
"""
    print(help_text)

def list_packages():
    """List all packages defined in this script."""
    print(f"📦 Taps ({len(TAPS)}):")
    for tap in TAPS:
        print(f"  {tap}")
    print()

    # Count unique formulas (SPECIAL_FORMULAS overrides duplicates in FORMULAS)
    special_basenames = get_special_formula_basenames()
    regular_formulas = [f for f in FORMULAS if normalize_formula_name(f) not in special_basenames]
    total_formulas = len(regular_formulas) + len(SPECIAL_FORMULAS)

    print(f"🔧 Formulas ({total_formulas}):")
    for formula in regular_formulas:
        print(f"  {formula}")
    for formula, flags in SPECIAL_FORMULAS:
        if flags:
            print(f"  {formula} {flags} (special)")
        else:
            print(f"  {formula} (special)")
    print()

    print(f"🖥️  Casks ({len(CASKS)}):")
    for cask in CASKS:
        print(f"  {cask}")
    print()

    print(f"Total: {len(TAPS)} taps, {total_formulas} formulas, {len(CASKS)} casks")

def show_diff():
    """Show difference between defined and installed packages."""
    print("📊 Comparing defined packages vs installed packages...")
    print()

    # Cache installed packages for O(1) lookup
    print("📋 Caching installed packages...")
    installed_formulas_cache = set(get_installed_formulas())
    installed_casks_cache = set(get_installed_casks())
    print(f"  Found {len(installed_formulas_cache)} formulas, {len(installed_casks_cache)} casks")
    print()

    _, wanted_normalized = get_all_wanted_formulas()
    # Use leaves for removal decisions (don't remove dependencies)
    installed_leaves = get_installed_formula_leaves()

    # Formulas to install (check using full names from lists)
    print("🔧 Formulas:")
    special_basenames = get_special_formula_basenames()
    missing_formulas = []

    # Check regular formulas (skip if in SPECIAL_FORMULAS)
    for f in FORMULAS:
        basename = normalize_formula_name(f)
        if basename not in special_basenames and f not in installed_formulas_cache:
            missing_formulas.append(f)

    # Check special formulas
    for formula, flags in SPECIAL_FORMULAS:
        basename = get_formula_basename(formula)
        if basename not in installed_formulas_cache:
            missing_formulas.append(f"{formula} {flags}" if flags else formula)

    if missing_formulas:
        print(f"  ➕ To install: {' '.join(missing_formulas)}")
    else:
        print("  ✅ All defined formulas are installed")

    # Formulas to remove (compare normalized names)
    extra_formulas = [f for f in installed_leaves
                      if normalize_formula_name(f) not in wanted_normalized]
    if extra_formulas:
        print(f"  ➖ To remove (with --sync): {' '.join(extra_formulas)}")
    else:
        print("  ✅ No extra formulas installed")
    print()

    # Casks to install
    print("🖥️  Casks:")
    missing_casks = [c for c in CASKS if c not in installed_casks_cache]
    if missing_casks:
        print(f"  ➕ To install: {' '.join(missing_casks)}")
    else:
        print("  ✅ All defined casks are installed")

    # Casks to remove
    extra_casks = [c for c in installed_casks_cache if c not in CASKS]
    if extra_casks:
        print(f"  ➖ To remove (with --sync): {' '.join(extra_casks)}")
    else:
        print("  ✅ No extra casks installed")
    print()

def sync_packages(dry_run: bool, cascade: bool):
    """Remove packages not in the defined lists."""
    print("🔄 Checking for packages to remove...")
    print()

    _, wanted_normalized = get_all_wanted_formulas()
    # Use leaves for removal decisions (don't remove dependencies)
    installed_leaves = get_installed_formula_leaves()
    installed_casks = get_installed_casks()

    # Remove unlisted formulas (compare normalized names to handle tap paths)
    print("  Checking installed formulas...")
    formulas_to_remove = [f for f in installed_leaves
                          if normalize_formula_name(f) not in wanted_normalized]

    if formulas_to_remove:
        print(f"  📦 Formulas to remove: {' '.join(formulas_to_remove)}")
        for formula in formulas_to_remove:
            print(f"    Removing {formula}...")
            if cascade:
                run_cmd(["brew", "uninstall", "--force", "--ignore-dependencies", formula], dry_run)
            else:
                result = run_cmd(["brew", "uninstall", formula], dry_run, capture=not dry_run)
                if result and result.returncode != 0:
                    print("      ⚠️  Skipped (has dependents, use --cascade to force)")
    else:
        print("  ✅ No formulas to remove")
    print()

    # Remove unlisted casks
    print("  Checking installed casks...")
    casks_to_remove = [c for c in installed_casks if c not in CASKS]

    if casks_to_remove:
        print(f"  📦 Casks to remove: {' '.join(casks_to_remove)}")
        for cask in casks_to_remove:
            print(f"    Removing {cask}...")
            run_cmd(["brew", "uninstall", "--cask", cask], dry_run)
    else:
        print("  ✅ No casks to remove")
    print()

def install_packages(dry_run: bool) -> tuple[int, int, int]:
    """Install all defined packages. Returns (taps_added, formulas_installed, casks_installed)."""
    taps_added = 0
    formulas_installed = 0
    casks_installed = 0

    # Cache installed packages for O(1) lookup (major performance optimization)
    print("📋 Caching installed packages...")
    installed_formulas_cache = set(get_installed_formulas())
    installed_casks_cache = set(get_installed_casks())
    print(f"  Found {len(installed_formulas_cache)} formulas, {len(installed_casks_cache)} casks")
    print()

    # Taps
    print("📦 Adding taps...")
    tapped = get_tapped_repos()
    for tap in TAPS:
        if tap not in tapped:
            print(f"  Tapping {tap}...")
            run_cmd(["brew", "tap", tap], dry_run)
            taps_added += 1
    if taps_added == 0:
        print("  ✅ All taps already added")
    print()

    # Get basenames of special formulas to skip them in regular install
    special_basenames = get_special_formula_basenames()

    # Collect missing standard formulas for batch install
    print("🔧 Installing formulas...")
    missing_formulas = []
    for formula in FORMULAS:
        basename = normalize_formula_name(formula)
        if basename in special_basenames:
            continue
        if formula not in installed_formulas_cache:
            missing_formulas.append(formula)

    if missing_formulas:
        print(f"  Installing {len(missing_formulas)} formulas: {' '.join(missing_formulas)}")
        run_cmd(["brew", "install"] + missing_formulas, dry_run)
        formulas_installed += len(missing_formulas)
    else:
        print("  ✅ All standard formulas already installed")
    print()

    # Special formulas with flags (must be installed individually due to different flags)
    print("🔧 Installing formulas with special flags...")
    special_installed = 0
    for formula, flags in SPECIAL_FORMULAS:
        basename = get_formula_basename(formula)
        if basename not in installed_formulas_cache:
            if flags:
                print(f"  Installing {formula} {flags}...")
                run_cmd(["brew", "install", formula, flags], dry_run)
            else:
                print(f"  Installing {formula}...")
                run_cmd(["brew", "install", formula], dry_run)
            special_installed += 1
    if special_installed == 0:
        print("  ✅ All special formulas already installed")
    formulas_installed += special_installed
    print()

    # Collect missing casks for batch install
    print("🖥️  Installing casks...")
    missing_casks = [cask for cask in CASKS if cask not in installed_casks_cache]

    if missing_casks:
        print(f"  Installing {len(missing_casks)} casks: {' '.join(missing_casks)}")
        run_cmd(["brew", "install", "--cask"] + missing_casks, dry_run)
        casks_installed = len(missing_casks)
    else:
        print("  ✅ All casks already installed")
    print()

    return taps_added, formulas_installed, casks_installed

# =============================================================================
# MAIN
# =============================================================================

def main():
    parser = ArgumentParser(add_help=False)
    parser.add_argument("--help", "-h", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--sync", action="store_true")
    parser.add_argument("--cascade", action="store_true")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--diff", action="store_true")

    args = parser.parse_args()

    # Handle cascade implying sync
    if args.cascade:
        args.sync = True

    # Handle special modes
    if args.help:
        show_help()
        return

    if args.list:
        list_packages()
        return

    if args.diff:
        show_diff()
        return

    # Main execution
    print("🍺 Homebrew Package Manager (Xonsh)")
    print("====================================")
    if args.dry_run:
        print("🔍 Dry run mode - commands will be printed but not executed")
    if args.sync:
        print("🔄 Sync mode - will remove unlisted packages")
        if args.cascade:
            print("⚠️  Cascade mode - will force-remove packages with dependents")
    print()

    # Sync mode: remove unlisted packages first
    if args.sync:
        sync_packages(args.dry_run, args.cascade)

    # Install packages
    taps_added, formulas_installed, casks_installed = install_packages(args.dry_run)

    # Summary
    print("✅ Complete!")
    print()
    print("Summary:")
    print(f"  - Taps added: {taps_added}")
    print(f"  - Formulas installed: {formulas_installed}")
    print(f"  - Casks installed: {casks_installed}")
    print()
    print("Tips:")
    print("  - Run 'brew upgrade' to update all packages")
    print("  - Run 'brew cleanup' to remove old versions")
    print("  - Run 'brew-install-all.xsh --diff' to check for drift")
    if args.dry_run:
        print()
        print("🔍 This was a dry run. Run without --dry-run to apply changes.")

if __name__ == "__main__" or True:  # Always run in xonsh
    main()
