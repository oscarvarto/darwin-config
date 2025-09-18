#!/usr/bin/env bash
# ~/.doom.d/shell-profiles.sh
#
# DEPRECATED: Multiple Doom Emacs Profile System
# This file is disabled to prevent conflicts with home-manager service
# The home-manager service now manages a single unified daemon
#
# Use instead:
#   emacs-service-toggle start/stop/restart
#   emacsclient-gui (for Raycast)
#   e, t, et (shell aliases)

exit 0

# =============================================================================
# EMACS PROFILE FUNCTIONS (DISABLED)
# =============================================================================

# Function to start Emacs with minimal configuration (fastest startup)
emacs-minimal() {
    echo "🚀 Starting Emacs with minimal profile..."
    DOOM_PROFILE=minimal "$HOME/.nix-profile/bin/emacs" "$@"
}

# Function to start Emacs with development profile (balanced)
emacs-dev() {
    echo "⚡ Starting Emacs with development profile..."
    DOOM_PROFILE=dev "$HOME/.nix-profile/bin/emacs" "$@"
}

# Function to start Emacs with full profile (current setup)
emacs-full() {
    echo "🔥 Starting Emacs with full profile..."
    DOOM_PROFILE=full "$HOME/.nix-profile/bin/emacs" "$@"
}

# Function to start Emacs daemon with specific profile
emacs-daemon() {
    local profile=${1:-full}
    echo "🌟 Starting Emacs daemon with $profile profile..."
    DOOM_PROFILE=$profile "$HOME/.nix-profile/bin/emacs" --daemon=doom-$profile
}

# Function to connect to specific daemon profile
emacs-client() {
    local profile=${1:-full}
    local socket_name="doom-$profile"
    echo "📡 Connecting to daemon: $socket_name"
    "$HOME/.nix-profile/bin/emacsclient" -s $socket_name -c "$@"
}

# =============================================================================
# OPTIMIZATION ALIASES
# =============================================================================

# Quick aliases for common tasks
alias e-min='emacs-minimal'
alias e-dev='emacs-dev'  
alias e-full='emacs-full'

# Daemon management
alias ed-min='emacs-daemon minimal'
alias ed-dev='emacs-daemon dev'
alias ed-full='emacs-daemon full'

# Client connections
alias ec-min='emacs-client minimal'
alias ec-dev='emacs-client dev'
alias ec-full='emacs-client full'

# =============================================================================
# BENCHMARK HELPERS
# =============================================================================

# Function to benchmark all profiles
benchmark-emacs() {
    echo "🧪 Benchmarking all Emacs profiles..."
    
    echo "Testing minimal profile..."
    time DOOM_PROFILE=minimal "$HOME/.nix-profile/bin/emacs" --batch --eval "(message \"Minimal profile loaded\")"
    
    echo "Testing dev profile..."
    time DOOM_PROFILE=dev "$HOME/.nix-profile/bin/emacs" --batch --eval "(message \"Dev profile loaded\")"
    
    echo "Testing full profile..."
    time DOOM_PROFILE=full "$HOME/.nix-profile/bin/emacs" --batch --eval "(message \"Full profile loaded\")"
}

# Function to show current profile
show-emacs-profile() {
    echo "Current DOOM_PROFILE: ${DOOM_PROFILE:-full (default)}"
}

# =============================================================================
# USAGE EXAMPLES
# =============================================================================

# Show usage information
emacs-help() {
    cat << 'EOF'
🎯 Doom Emacs Profile System Usage:

BASIC USAGE:
  emacs-minimal [files...]  # Fast startup, basic editing
  emacs-dev [files...]      # Development-focused features  
  emacs-full [files...]     # Complete feature set

DAEMON MODE:
  emacs-daemon [profile]    # Start daemon with profile
  emacs-client [profile]    # Connect to daemon

QUICK ALIASES:
  e-min, e-dev, e-full      # Start with profile
  ed-min, ed-dev, ed-full   # Start daemon
  ec-min, ec-dev, ec-full   # Connect to daemon

EXAMPLES:
  e-dev myfile.rs           # Open Rust file with dev profile
  ed-full && ec-full        # Start full daemon and connect
  benchmark-emacs           # Test all profile speeds

EXPECTED PERFORMANCE:
  minimal: ~2-4 seconds     # Basic editing, git, org
  dev:     ~4-7 seconds     # LSP, debugging, languages  
  full:    ~8-12 seconds    # All features (current)
EOF
}

# Show help when sourced
echo "✅ Emacs profile system loaded! Run 'emacs-help' for usage."
