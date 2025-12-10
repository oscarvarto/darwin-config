#!/usr/bin/env xonsh
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
# Generated from: brew list (2025-12-09)
# Location: ~/darwin-config/stow/aux-scripts/.local/share/bin/brew-install-all.xsh

import sys
import subprocess
from argparse import ArgumentParser

# =============================================================================
# PACKAGE DEFINITIONS
# =============================================================================

# Taps (third-party repositories)
TAPS = [
    "borkdude/brew",
    "jetbrains/utils",
    "jimeh/emacs-builds",
    "oscarvarto/jank",
]

# Standard formulas (no special flags)
FORMULAS = [
    # Development tools
    "angular-cli",
    "awscli",
    "babashka",
    "bash-language-server",
    "bazelisk",
    "bfg",
    "boot-clj",
    "cargo-binstall",
    "ccache",
    "cljfmt",
    "clojure",
    "clojure-lsp",
    "cmake",
    "cmake-language-server",
    "cypher-shell",
    "difftastic",
    "entr",
    "fernflower",
    "foreman",
    "gcc",
    "gemini-cli",
    "gh",
    "git-filter-repo",
    "git-lfs",
    "glab",
    "go",
    "gradle",
    "gradle-completion",
    "helix",
    "hugo",
    "jiratui",
    "kotlin-lsp",
    "markdown-oxide",
    "markdownlint-cli2",
    "maven",
    "minio",
    "ninja",
    "node",
    "ollama",
    "openjdk",
    "openjdk@21",
    "pass",
    "podman",
    "podman-tui",
    "prettier",
    "pueue",
    "ripgrep",
    "sbcl",
    "stow",
    "tesseract",
    "tombi",
    "tree-sitter-cli",
    "vcpkg",
    "vim",
    "volta",
    "xcode-build-server",
    "yq",
    "z3",
    "zig",

    # Media tools
    "aria2",
    "bat",
    "bat-extras",
    "eza",
    "ffmpeg",
    "fontforge",
    "ghostscript",
    "imagemagick",
    "multimarkdown",
    "resvg",
    "vivid",

    # Databases
    "mysql@8.4",
    "neo4j",
    "postgresql@15",

    # System utilities
    "atuin",
    "gnu-getopt",
    "gnu-tar",
    "gnupg",
    "grep",
    "gzip",
    "jq",
    "livekit",
    "mas",
    "pinentry-mac",
    "rlwrap",
    "sevenzip",
    "swig",
    "trash-cli",
    "tree",
    "wmctrl",
    "zip",

    # Libraries (some are needed for compilation)
    "libgccjit",
    "libsql",
    "libvterm",
    "llvm@20",
    "lld@20",
    "zeromq",
]

# Formulas with special flags: list of (formula, flags) tuples
# Use full tap/name for custom taps
SPECIAL_FORMULAS = [
    ("llvm", "--HEAD"),
    ("lld", "--HEAD"),
    ("oscarvarto/jank/jank-git", ""),
]

# Casks (GUI applications)
CASKS = [
    # Productivity
    "1password-cli",
    "1password@nightly",
    "anytype",
    "chatgpt",
    "chatgpt-atlas",
    "claude",
    "claude-code",
    "codex",
    "dropbox",
    "fastmail",
    "figma",
    "microsoft-outlook",
    "microsoft-teams",
    "obsidian",
    "postman",
    "raycast",
    "signal",
    "slack",
    "snagit",
    "teamviewer",
    "whatsapp",
    "zoom",

    # Development
    "chromedriver",
    "cljstyle",
    "dotnet-sdk",
    "emacs-app-nightly",
    "gg",
    "ghostty@tip",
    "jetbrains-toolbox",
    "kitty",
    "miniforge",
    "neo4j-desktop",
    "qt-creator",
    "qt-design-studio",
    "visual-studio-code@insiders",

    # Browsers
    "google-chrome",
    "safari-technology-preview",
    "zen",

    # Media
    "discord",
    "gimp",
    "ollama-app",
    "tidal",

    # System utilities
    "balenaetcher",
    "nordvpn",
    "powershell",
    "unnaturalscrollwheels",

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

def get_all_wanted_formulas() -> list[str]:
    """Build complete list of wanted formula names."""
    formulas = list(FORMULAS)
    for formula, _ in SPECIAL_FORMULAS:
        formulas.append(get_formula_basename(formula))
    return formulas

def get_installed_formulas() -> list[str]:
    """Get list of installed formula leaves."""
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

    total_formulas = len(FORMULAS) + len(SPECIAL_FORMULAS)
    print(f"🔧 Formulas ({total_formulas}):")
    for formula in FORMULAS:
        print(f"  {formula}")
    for formula, flags in SPECIAL_FORMULAS:
        if flags:
            print(f"  {formula} {flags}")
        else:
            print(f"  {formula}")
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

    wanted_formulas = get_all_wanted_formulas()
    installed_formulas = get_installed_formulas()
    installed_casks = get_installed_casks()

    # Formulas to install
    print("🔧 Formulas:")
    missing_formulas = [f for f in wanted_formulas if not is_formula_installed(f)]
    if missing_formulas:
        print(f"  ➕ To install: {' '.join(missing_formulas)}")
    else:
        print("  ✅ All defined formulas are installed")

    # Formulas to remove
    extra_formulas = [f for f in installed_formulas if f not in wanted_formulas]
    if extra_formulas:
        print(f"  ➖ To remove (with --sync): {' '.join(extra_formulas)}")
    else:
        print("  ✅ No extra formulas installed")
    print()

    # Casks to install
    print("🖥️  Casks:")
    missing_casks = [c for c in CASKS if not is_cask_installed(c)]
    if missing_casks:
        print(f"  ➕ To install: {' '.join(missing_casks)}")
    else:
        print("  ✅ All defined casks are installed")

    # Casks to remove
    extra_casks = [c for c in installed_casks if c not in CASKS]
    if extra_casks:
        print(f"  ➖ To remove (with --sync): {' '.join(extra_casks)}")
    else:
        print("  ✅ No extra casks installed")
    print()

def sync_packages(dry_run: bool, cascade: bool):
    """Remove packages not in the defined lists."""
    print("🔄 Checking for packages to remove...")
    print()

    wanted_formulas = get_all_wanted_formulas()
    installed_formulas = get_installed_formulas()
    installed_casks = get_installed_casks()

    # Remove unlisted formulas
    print("  Checking installed formulas...")
    formulas_to_remove = [f for f in installed_formulas if f not in wanted_formulas]

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

    # Standard formulas
    print("🔧 Installing formulas...")
    for formula in FORMULAS:
        if not is_formula_installed(formula):
            print(f"  Installing {formula}...")
            run_cmd(["brew", "install", formula], dry_run)
            formulas_installed += 1
    if formulas_installed == 0:
        print("  ✅ All standard formulas already installed")
    print()

    # Special formulas with flags
    print("🔧 Installing formulas with special flags...")
    special_installed = 0
    for formula, flags in SPECIAL_FORMULAS:
        basename = get_formula_basename(formula)
        if not is_formula_installed(basename):
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

    # Casks
    print("🖥️  Installing casks...")
    for cask in CASKS:
        if not is_cask_installed(cask):
            print(f"  Installing {cask}...")
            run_cmd(["brew", "install", "--cask", cask], dry_run)
            casks_installed += 1
    if casks_installed == 0:
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
