#!/usr/bin/env bash

# Nix Performance Optimizer
# Automatically detects hardware specs and optimizes Nix build settings
# Part of the darwin-config setup process

set -euo pipefail

VERSION="1.0.0"

show_help() {
  cat <<'HELP_EOF'
🚀 Nix Performance Optimizer v$VERSION

Automatically detects your system's hardware capabilities and optimizes Nix build
settings for faster compilation and better resource utilization.

USAGE:
    optimize-nix-performance.sh [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version information
    --dry-run          Show what would be changed without making changes
    --force            Apply optimizations even if already configured
    --verbose          Show detailed hardware detection information

WHAT IT DOES:
    • Detects CPU cores and memory capacity
    • Uses multiple jobs per core for maximum CPU utilization (3x cores for max-jobs)
    • Aggressive network downloads for fast substitution (4x cores, capped at 64)
    • Sets memory limits based on RAM (min-free: 5% or 2GB, max-free: 60% or 5GB)
    • Configures daemon I/O priority based on system resources
    • Updates system.nix with hardware-optimized static values

HARDWARE DETECTION:
    • CPU Cores: Uses sysctl hw.ncpu for logical core count
    • Memory: Uses sysctl hw.memsize for total RAM
    • Applies conservative defaults for stability
    • Optimizes for build speed vs system responsiveness

OUTPUT:
    Directly updates system.nix with hardware-optimized static values.
    Creates system.nix.backup before making changes.

EXAMPLES:
    optimize-nix-performance.sh              # Detect and apply optimizations
    optimize-nix-performance.sh --dry-run    # Preview changes
    optimize-nix-performance.sh --verbose    # Show detailed hardware info

NIX RUN USAGE:
    nix run .#optimize-nix-performance       # Basic optimization
    nix run .#optimize-nix-performance -- --dry-run     # Preview changes
    nix run .#optimize-nix-performance -- --force       # Force re-optimization
    nix run .#optimize-nix-performance -- --verbose     # Show detailed info

SHELL COMPATIBILITY:
    Works in both zsh and nushell environments.
    Requires DARWIN_CONFIG_PATH to point at your darwin-config checkout.

EXIT CODES:
    0    Success
    1    Error in optimization process
    2    Invalid command line arguments

HELP_EOF
}

show_version() {
  echo "Nix Performance Optimizer v$VERSION"
  echo "Hardware-aware Nix build configuration for macOS"
}

# Parse command line arguments
DRY_RUN=false
FORCE=false
VERBOSE=false

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
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --force)
    FORCE=true
    shift
    ;;
  --verbose)
    VERBOSE=true
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

# Output function for verbose mode
verbose_log() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo "$@"
  fi
}

# Detect hardware specifications
# ----------------------------------------------------------------------
# 1 Detect logical CPUs (the number Nix can actually schedule)
# ----------------------------------------------------------------------
if command -v nproc >/dev/null; then
  # Homebrew coreutils nproc respects logical CPUs on macOS
  CORES=$(nproc --all)
else
  # macOS native: hw.logicalcpu_max = total logical cores (incl. efficiency)
  CORES=$(sysctl -n hw.logicalcpu_max 2>/dev/null || echo 1)
fi

# ----------------------------------------------------------------------
# 2 Detect total RAM (bytes → GiB)
# ----------------------------------------------------------------------
MEM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
# Convert to GiB, round down
MEM_GIB=$((MEM_BYTES / 1024 / 1024 / 1024))

# ----------------------------------------------------------------------
# 3 Compute Nix‑friendly defaults (no arbitrary “/4” cap)
# ----------------------------------------------------------------------
# Use multiple jobs per core for maximum CPU utilization
# Modern processors with hyperthreading can handle 2-4 jobs per logical core
MAX_JOBS=$((CORES * 4))
[[ $MAX_JOBS -lt 1 ]] && MAX_JOBS=1

# Network downloads can be very aggressive - 4x cores up to 64
MAX_SUB_JOBS=$((CORES * 4))
[[ $MAX_SUB_JOBS -gt 64 ]] && MAX_SUB_JOBS=64
# Memory limits based on available RAM
# min-free: Keep 2GB minimum or 5% of RAM, whichever is larger
MIN_FREE_BYTES=$(echo "$MEM_GIB * 1024 * 1024 * 1024 * 0.05" | bc | cut -d. -f1)
[[ $MIN_FREE_BYTES -lt 2147483648 ]] && MIN_FREE_BYTES=2147483648 # 2GB minimum
MIN_FREE_DESC="$(echo "scale=1; $MIN_FREE_BYTES / 1024 / 1024 / 1024" | bc)GB"

# max-free: Trigger GC when using 60% of RAM or 5GB, whichever is larger
MAX_FREE_BYTES=$(echo "$MEM_GIB * 1024 * 1024 * 1024 * 0.6" | bc | cut -d. -f1)
[[ $MAX_FREE_BYTES -lt 5368709120 ]] && MAX_FREE_BYTES=5368709120 # 5GB minimum
MAX_FREE_DESC="$(echo "scale=1; $MAX_FREE_BYTES / 1024 / 1024 / 1024" | bc)GB"

# Upper‑bound workers: one per core, but never exceed 1/2 of RAM in GiB.
# Reasonable heuristic: each worker may need ~2 GiB in the worst case.

verbose_log "   Memory limits: min-free=$MIN_FREE_DESC, max-free=$MAX_FREE_DESC"

# ----------------------------------------------------------------------
# 4 Daemon I/O priority
# Give higher priority to Nix daemon on systems with plenty of resources
# ----------------------------------------------------------------------
if [[ $MEM_GIB -ge 16 && $CORES -ge 8 ]]; then
  DAEMON_IO_LOW_PRIORITY="false"
  DAEMON_PRIORITY_DESC="high (plenty of resources)"
else
  DAEMON_IO_LOW_PRIORITY="true"
  DAEMON_PRIORITY_DESC="low (conserve resources)"
fi

verbose_log "   Daemon I/O priority: $DAEMON_PRIORITY_DESC"

# ----------------------------------------------------------------------
# 5 Update system.nix with optimized static values
# ----------------------------------------------------------------------
echo "📝 Updating system.nix with hardware-optimized settings..."

# Resolve system.nix using DARWIN_CONFIG_PATH
if [[ -z "${DARWIN_CONFIG_PATH:-}" ]]; then
  echo "❌ DARWIN_CONFIG_PATH is not set."
  echo "   Run 'nix run .#record-config-path' in your darwin-config checkout,"
  echo "   then restart your shell before re-running this script."
  exit 1
fi

SYSTEM_NIX="${DARWIN_CONFIG_PATH}/system.nix"

if [[ ! -f "$SYSTEM_NIX" ]]; then
  echo "❌ Expected system.nix at $SYSTEM_NIX, but it was not found."
  echo "   Update DARWIN_CONFIG_PATH by running 'nix run .#record-config-path'."
  exit 1
fi

# Create backup of original system.nix
if [[ "$DRY_RUN" != "true" && "$FORCE" != "true" ]]; then
  if [[ ! -f "$SYSTEM_NIX.backup" ]]; then
    cp "$SYSTEM_NIX" "$SYSTEM_NIX.backup"
    echo "💾 Created backup: system.nix.backup"
  fi
fi

# Define the replacement patterns for system.nix
# These will replace the placeholder values with hardware-optimized ones

if [[ "$DRY_RUN" == "true" ]]; then
  echo "🔍 DRY RUN - Changes that would be made to system.nix:"
  echo ""
  echo "   max-jobs = \"auto\" → max-jobs = $MAX_JOBS"
  echo "   daemonIOLowPriority = true → daemonIOLowPriority = $DAEMON_IO_LOW_PRIORITY"
  echo ""
  echo "💡 Hardware detected: ${CORES} cores, ${MEM_GIB}GB RAM"
else
  # Check if already optimized
  if grep -q "# Hardware-optimized settings applied" "$SYSTEM_NIX" && [[ "$FORCE" != "true" ]]; then
    echo "⚠️  system.nix already contains hardware optimizations"
    echo "   Use --force to re-optimize, or --dry-run to preview changes"
    exit 1
  fi

  # Apply the optimizations using sed
  echo "   Applying max-jobs = $MAX_JOBS"
  sed -i '' "s/max-jobs = [^;]*;.*/max-jobs = $MAX_JOBS;        # Hardware-optimized: $CORES cores detected/" "$SYSTEM_NIX"

  echo "   Applying max-substitution-jobs = $MAX_SUB_JOBS"
  sed -i '' "s/max-substitution-jobs = [0-9]*;.*/max-substitution-jobs = $MAX_SUB_JOBS; # Hardware-optimized for network performance/" "$SYSTEM_NIX"

  echo "   Applying min-free = $MIN_FREE_BYTES"
  sed -i '' "s/min-free = [0-9]*;.*/min-free = $MIN_FREE_BYTES;    # Hardware-optimized: $MIN_FREE_DESC minimum/" "$SYSTEM_NIX"

  echo "   Applying max-free = $MAX_FREE_BYTES"
  sed -i '' "s/max-free = [0-9]*;.*/max-free = $MAX_FREE_BYTES;    # Hardware-optimized: $MAX_FREE_DESC threshold/" "$SYSTEM_NIX"

  echo "   Applying daemon I/O priority = $DAEMON_IO_LOW_PRIORITY"
  sed -i '' "s/daemonIOLowPriority = [a-z]*;.*/daemonIOLowPriority = $DAEMON_IO_LOW_PRIORITY;      # Hardware-optimized: $DAEMON_PRIORITY_DESC/" "$SYSTEM_NIX"

  # Add a marker comment to indicate optimization was applied
  if ! grep -q "# Hardware-optimized settings applied" "$SYSTEM_NIX"; then
    sed -i '' "/# Dynamic build performance settings based on hardware specs/a\\
      # Hardware-optimized settings applied on $(date) for ${CORES} cores, ${MEM_GIB}GB RAM
" "$SYSTEM_NIX"
  fi

  echo "✅ Successfully updated system.nix with hardware-optimized settings"
fi

# Summary
echo ""
echo "🎯 Hardware Optimization Summary:"
echo "   CPU Cores: $CORES"
echo "   Memory: ${MEM_GIB}GB"
echo "   Max Jobs: $MAX_JOBS"
echo "   Max Downloads: $MAX_SUB_JOBS"
echo "   Memory Limits: $MIN_FREE_DESC min, $MAX_FREE_DESC max"
echo "   I/O Priority: $DAEMON_PRIORITY_DESC"

if [[ "$DRY_RUN" != "true" ]]; then
  echo ""
  echo "🚀 Next Steps:"
  echo "   1. Review the updated system.nix file"
  echo "   2. Rebuild your system: nb && ns"
  echo "   3. Your builds should now be faster and use more system resources"
  echo ""
  echo "💡 To revert: restore from system.nix.backup and rebuild"
  echo "   cp system.nix.backup system.nix && nb && ns"
fi
