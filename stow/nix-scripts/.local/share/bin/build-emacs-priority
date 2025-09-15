#!/usr/bin/env bash

# Emacs Priority Build Script
# Builds Emacs with maximum system resources, then continues with other derivations

set -euo pipefail

# Set locale environment early to prevent locale warnings
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"

VERSION="1.0.0"

show_help() {
  cat <<'HELP_EOF'
🚀 Emacs Priority Build Script v$VERSION

Builds Emacs with dedicated system resources for fastest compilation,
then optionally continues with full system rebuild.

USAGE:
    build-emacs-priority [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version information
    --emacs-only        Build only Emacs (don't continue with system rebuild)
    --continue-build    After Emacs, continue with full system rebuild
    --verbose           Show detailed build information
    --dry-run          Show what would be built without building

WHAT IT DOES:
    1. Auto-detects your darwin-config directory location
    2. Detects your system configuration (hostname, user, hardware)
    3. Builds Emacs with max-jobs=48, cores=0 (all resources)
    4. Optionally continues with system rebuild using balanced settings

DIRECTORY DETECTION:
    Automatically searches for darwin-config in common locations:
    • ~/darwin-config
    • ~/.config/darwin-config
    • ~/src/darwin-config
    • ~/projects/darwin-config
    • ~/code/darwin-config
    • Current working directory
    • Script's parent directory

EXAMPLES:
    build-emacs-priority                       # Build Emacs only (from anywhere)
    build-emacs-priority --continue-build      # Build Emacs, then full system
    build-emacs-priority --dry-run             # Preview what would be built
    cd /tmp && build-emacs-priority            # Works from any directory

EXIT CODES:
    0    Success
    1    Build error
    2    Configuration error

HELP_EOF
}

show_version() {
  echo "Emacs Priority Build Script v$VERSION"
  echo "Dedicated resource allocation for Emacs compilation"
}

# Parse command line arguments
EMACS_ONLY=true
CONTINUE_BUILD=false
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    show_help
    exit 0
    ;;
  -v | --version)
    show_version
    exit 0
    ;;
  --emacs-only)
    EMACS_ONLY=true
    CONTINUE_BUILD=false
    shift
    ;;
  --continue-build)
    EMACS_ONLY=false
    CONTINUE_BUILD=true
    shift
    ;;
  --verbose)
    VERBOSE=true
    shift
    ;;
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  -*)
    echo "Error: Unknown option $1" >&2
    echo "Use --help for usage information" >&2
    exit 2
    ;;
  *)
    echo "Error: Unexpected argument $1" >&2
    echo "Use --help for usage information" >&2
    exit 2
    ;;
  esac
done

# Detect system configuration
HOSTNAME=$(hostname -s)
USER=$(whoami)

verbose_log() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo "$@"
  fi
}

# Detect hardware for optimal settings
if command -v nproc >/dev/null; then
  CORES=$(nproc --all)
else
  CORES=$(sysctl -n hw.logicalcpu_max 2>/dev/null || echo 16)
fi

# Maximum resources for Emacs
EMACS_MAX_JOBS=$((CORES * 3))  # Same as your system setting
EMACS_CORES=0  # Use all cores

# Balanced resources for system rebuild
SYSTEM_MAX_JOBS=$((CORES * 2))  # Slightly more conservative
SYSTEM_CORES=0

verbose_log "🔧 Detected hardware: $CORES logical cores"
verbose_log "📦 Emacs build settings: max-jobs=$EMACS_MAX_JOBS, cores=$EMACS_CORES"
verbose_log "🏗️  System build settings: max-jobs=$SYSTEM_MAX_JOBS, cores=$SYSTEM_CORES"

echo "🎯 Emacs Priority Build Starting..."
echo "   Hardware: $CORES cores detected"
echo "   Emacs max-jobs: $EMACS_MAX_JOBS (dedicated resources)"

if [[ "$CONTINUE_BUILD" == "true" ]]; then
  echo "   System max-jobs: $SYSTEM_MAX_JOBS (after Emacs)"
fi

# Auto-detect darwin-config directory
DARWIN_CONFIG_DIR=""

# Function to find darwin-config directory
find_darwin_config() {
  local search_dirs=(
    "$HOME/darwin-config"
    "$HOME/.config/darwin-config"
    "$HOME/src/darwin-config"
    "$HOME/projects/darwin-config"
    "$HOME/code/darwin-config"
    "$PWD"  # Current directory
    "$(dirname "$0")/.."  # Script's parent directory
  )

  for dir in "${search_dirs[@]}"; do
    if [[ -d "$dir" ]] && [[ -f "$dir/flake.nix" ]] && [[ -f "$dir/system.nix" ]]; then
      echo "$(cd "$dir" && pwd)"  # Return absolute path
      return 0
    fi
  done

  return 1
}

verbose_log "🔍 Searching for darwin-config directory..."

if DARWIN_CONFIG_DIR=$(find_darwin_config); then
  verbose_log "   Found: $DARWIN_CONFIG_DIR"
  cd "$DARWIN_CONFIG_DIR" || {
    echo "❌ Error: Cannot change to darwin-config directory: $DARWIN_CONFIG_DIR"
    exit 2
  }
else
  echo "❌ Error: Cannot find darwin-config directory"
  echo "   Searched in:"
  echo "     • $HOME/darwin-config"
  echo "     • $HOME/.config/darwin-config"
  echo "     • $HOME/src/darwin-config"
  echo "     • $HOME/projects/darwin-config"
  echo "     • $HOME/code/darwin-config"
  echo "     • Current directory: $PWD"
  echo "     • Script directory: $(dirname "$0")/.."
  echo ""
  echo "   Please ensure your darwin-config directory contains flake.nix and system.nix"
  exit 2
fi

echo "📂 Using darwin-config: $DARWIN_CONFIG_DIR"

# Build Emacs with maximum resources
echo ""
echo "🚀 Phase 1: Building Emacs with dedicated resources..."

if [[ "$DRY_RUN" == "true" ]]; then
  echo "🔍 DRY RUN - Would execute:"
  echo "   # Building configured Emacs (emacs-git with pinning + custom build options)"
  echo "   nix build --max-jobs $EMACS_MAX_JOBS --cores $EMACS_CORES .#darwinConfigurations.$HOSTNAME.config.home-manager.users.$USER.services.emacs.package"
  echo ""
  echo "   This builds the emacs-git version with:"
  echo "   • Version pinning support (respects ~/.cache/emacs-git-pin)"
  echo "   • Native compilation enabled"
  echo "   • Custom build options (Tree-sitter, ImageMagick, Xwidgets, etc.)"
  echo "   • Verbose build progress indicators"
else
  verbose_log "   Executing: nix build configured Emacs with max-jobs=$EMACS_MAX_JOBS"

  # Build the configured Emacs with dedicated resources
  echo "📦 Building configured Emacs (emacs-git with custom options)..."
  echo "   • Respects emacs-pinning.nix settings"
  echo "   • Includes native compilation and enhanced features"
  echo "   • Uses verbose build progress indicators"
  echo ""

  verbose_log "   Locale environment: LANG=$LANG, LC_ALL=$LC_ALL"

  if nix build --max-jobs "$EMACS_MAX_JOBS" --cores "$EMACS_CORES" \
      ".#darwinConfigurations.$HOSTNAME.config.home-manager.users.$USER.services.emacs.package"; then
    echo "✅ Configured Emacs build completed successfully!"
  else
    echo "❌ Configured Emacs build failed!"
    exit 1
  fi
fi

# Continue with system build if requested
if [[ "$CONTINUE_BUILD" == "true" ]]; then
  echo ""
  echo "🏗️  Phase 2: Building remaining system with balanced resources..."

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "🔍 DRY RUN - Would execute:"
    echo "   nix run .#build -- --max-jobs $SYSTEM_MAX_JOBS --cores $SYSTEM_CORES"
  else
    verbose_log "   Executing: nix run .#build with max-jobs=$SYSTEM_MAX_JOBS"

    echo "🔧 Building remaining system..."
    if nix run .#build -- --max-jobs "$SYSTEM_MAX_JOBS" --cores "$SYSTEM_CORES"; then
      echo "✅ System build completed successfully!"
    else
      echo "❌ System build failed!"
      exit 1
    fi
  fi
fi

echo ""
echo "🎉 Build process completed!"

if [[ "$EMACS_ONLY" == "true" && "$DRY_RUN" != "true" ]]; then
  echo ""
  echo "💡 Next steps:"
  echo "   • Emacs is built and ready to use"
  echo "   • Run 'nb && ns' to rebuild and switch your full system"
  echo "   • Or run '$0 --continue-build' to continue with system rebuild"
fi

if [[ "$CONTINUE_BUILD" == "true" && "$DRY_RUN" != "true" ]]; then
  echo ""
  echo "💡 Next steps:"
  echo "   • Run 'ns' to switch to the newly built configuration"
  echo "   • Your optimized Emacs is ready to use!"
fi