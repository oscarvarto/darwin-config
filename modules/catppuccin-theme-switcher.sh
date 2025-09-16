#!/usr/bin/env bash

# Catppuccin Theme Switcher
# Automatically switches themes across all supported applications

VERSION="1.2.0"

show_help() {
    cat << 'HELP_EOF'
🎨 Catppuccin Theme Switcher v$VERSION

A unified theme switcher that synchronizes Catppuccin themes across all your applications
based on macOS system appearance or manual selection.

USAGE:
    catppuccin-theme-switcher [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version information
    -s, --status        Show current theme status across all applications
    -f, --force-light   Force light theme (Catppuccin Latte) regardless of system setting
    -d, --force-dark    Force dark theme (Catppuccin Mocha) regardless of system setting
    -a, --auto          Use automatic system appearance detection (default)
    -q, --quiet         Run silently without output
    --dry-run          Show what would be changed without making changes

SUPPORTED APPLICATIONS:
    • Starship (shell prompt) - Automatically managed by Nix Catppuccin module
    • BAT (syntax highlighter) - Automatically managed by Nix Catppuccin module
    • Zellij (terminal multiplexer) - Automatically managed by Nix Catppuccin module
    • Atuin (shell history)
    • Ghostty (terminal emulator) - Live config reload without restart
    • Nushell (shell syntax highlighting)
    • Fish (shell colors)
    • Zsh (shell colors)

THEME MAPPING:
    Light Mode:  Catppuccin Latte (official built-in theme)
    Dark Mode:   Catppuccin Mocha (official built-in theme)

AUTOMATIC MODE:
    The script automatically detects macOS system appearance:
    • System Light Mode → Catppuccin Latte
    • System Dark Mode  → Catppuccin Mocha

EXAMPLES:
    catppuccin-theme-switcher              # Auto-detect and apply theme
    catppuccin-theme-switcher --status     # Show current theme status
    catppuccin-theme-switcher --force-dark # Force dark theme
    catppuccin-theme-switcher --force-light --quiet # Force light theme silently
    catppuccin-theme-switcher --dry-run    # Preview changes

INTEGRATION:
    This script runs automatically when macOS appearance changes via LaunchAgent.
    Manual theme switching functions are also available:
    • catppuccin-theme-switch (alias)
    • ghostty-theme-light.nu / ghostty-theme-dark.nu (Ghostty-specific)

FILES:
    ~/.cache/nushell_theme    Theme cache for Nushell
    ~/.cache/fish_theme       Theme cache for Fish
    ~/.cache/zsh_theme        Theme cache for Zsh

EXIT CODES:
    0    Success
    1    Error in theme switching
    2    Invalid command line arguments

HELP_EOF
}

show_version() {
    echo "Catppuccin Theme Switcher v$VERSION"
    echo "Unified theme management for macOS development environment"
}

show_status() {
    echo "🔍 Current Theme Status:"
    echo ""
    
    # System appearance
    if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q "Dark"; then
        echo "🖥️  System Appearance: Dark"
    else
        echo "🖥️  System Appearance: Light"
    fi
    
    # Theme cache files
    echo "📁 Theme Cache Files:"
    for cache_file in ~/.cache/nushell_theme ~/.cache/fish_theme ~/.cache/zsh_theme; do
        if [[ -f "$cache_file" ]]; then
            theme=$(cat "$cache_file" 2>/dev/null || echo "unknown")
            echo "   $(basename "$cache_file"): $theme"
        else
            echo "   $(basename "$cache_file"): not set"
        fi
    done
    
    # Application-specific themes
    echo ""
    echo "🎨 Application Themes:"
    
    # Starship
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        echo "   Starship: Managed by Nix Catppuccin (automatic theme switching)"
    else
        echo "   Starship: not configured"
    fi
    
    # BAT
    if [[ -f "$HOME/.config/bat/config" ]]; then
        bat_theme=$(grep '^--theme=' "$HOME/.config/bat/config" | sed "s/--theme='\(.*\)'/\1/" || echo "unknown")
        echo "   BAT: $bat_theme (Nix Catppuccin managed)"
    else
        echo "   BAT: not configured"
    fi
    
    # Atuin
    if [[ -f "$HOME/.config/atuin/config.toml" ]]; then
        atuin_theme=$(grep 'name = ' "$HOME/.config/atuin/config.toml" | sed 's/name = "\(.*\)"/\1/' || echo "unknown")
        echo "   Atuin: $atuin_theme"
    else
        echo "   Atuin: not configured"
    fi
    
    # Zellij
    if [[ -f "$HOME/.config/zellij/config.kdl" ]]; then
        echo "   Zellij: Managed by Nix Catppuccin (automatic theme switching)"
    else
        echo "   Zellij: not configured"
    fi
    
    # Ghostty
    if [[ -f "$HOME/.config/ghostty/overrides.conf" ]]; then
        ghostty_theme=$(grep '^theme = ' "$HOME/.config/ghostty/overrides.conf" | sed 's/theme = \(.*\)/\1/' || echo "unknown")
        echo "   Ghostty: $ghostty_theme"
    else
        echo "   Ghostty: not configured"
    fi
    
    echo ""
}

# Parse command line arguments
FORCE_THEME=""
QUIET=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -s|--status)
            show_status
            exit 0
            ;;
        -f|--force-light)
            FORCE_THEME="light"
            shift
            ;;
        -d|--force-dark)
            FORCE_THEME="dark"
            shift
            ;;
        -a|--auto)
            FORCE_THEME=""
            shift
            ;;
        -q|--quiet)
            QUIET=true
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

# Check for manual override file
MANUAL_OVERRIDE_FILE="$HOME/.cache/catppuccin_manual_override"
MANUAL_OVERRIDE=""
if [[ -f "$MANUAL_OVERRIDE_FILE" ]]; then
    MANUAL_OVERRIDE=$(cat "$MANUAL_OVERRIDE_FILE" 2>/dev/null | head -n1 | tr -d '\n')
fi

# Output function that respects quiet mode
log() {
    if [[ "$QUIET" != "true" ]]; then
        echo "$@"
    fi
}

# Store original arguments as string to work around Nix string interpolation
ORIGINAL_ARGS="$*"

# Check if --auto was used to clear override first
if [[ "$ORIGINAL_ARGS" == *"--auto"* ]] || [[ "$ORIGINAL_ARGS" == *"-a"* ]]; then
    rm -f "$MANUAL_OVERRIDE_FILE" 2>/dev/null
    log "🔄 Cleared manual override - back to automatic mode"
    MANUAL_OVERRIDE=""  # Clear override so it won't be used
fi

# Determine theme based on priority: CLI args > manual override > system appearance
if [[ -n "$FORCE_THEME" ]]; then
    APPEARANCE="$FORCE_THEME"
    # If this is a manual force, save it as override (but not for --auto)
    if [[ "$FORCE_THEME" == "light" && "$ORIGINAL_ARGS" != *"--auto"* && "$ORIGINAL_ARGS" != *"-a"* ]]; then
        echo "light" > "$MANUAL_OVERRIDE_FILE"
        log "💾 Saved light theme as manual override"
    elif [[ "$FORCE_THEME" == "dark" && "$ORIGINAL_ARGS" != *"--auto"* && "$ORIGINAL_ARGS" != *"-a"* ]]; then
        echo "dark" > "$MANUAL_OVERRIDE_FILE"
        log "💾 Saved dark theme as manual override"
    fi
elif [[ -n "$MANUAL_OVERRIDE" && ("$MANUAL_OVERRIDE" == "light" || "$MANUAL_OVERRIDE" == "dark") ]]; then
    APPEARANCE="$MANUAL_OVERRIDE"
    log "🔒 Using manual override: $MANUAL_OVERRIDE mode"
elif defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q "Dark"; then
    APPEARANCE="dark"
else
    APPEARANCE="light"
fi

# Set theme variables
if [[ "$APPEARANCE" == "dark" ]]; then
    CATPPUCCIN_FLAVOR="mocha"
else
    CATPPUCCIN_FLAVOR="latte"
fi

# Dry run prefix
if [[ "$DRY_RUN" == "true" ]]; then
    log "🔍 DRY RUN MODE - No changes will be made"
    log ""
fi

log "🎨 Catppuccin Theme Switcher"
if [[ -n "$FORCE_THEME" ]]; then
    log "🔧 Mode: Forced $APPEARANCE mode"
else
    log "🔧 Mode: Auto-detect (system appearance: $APPEARANCE)"
fi
log "🎨 Catppuccin flavor: $CATPPUCCIN_FLAVOR"
log ""

# Starship theme is now automatically managed by Nix Catppuccin module
log "⭐ Starship prompt theme: Managed by Nix Catppuccin (automatic)"

# Update atuin theme via environment variables (Nix-managed configs are read-only)
log "📖 Updating Atuin history theme..."
ATUIN_OVERRIDE="$HOME/.config/atuin/overrides.toml"
if [[ "$DRY_RUN" != "true" ]]; then
    mkdir -p "$(dirname "$ATUIN_OVERRIDE")"
    if [[ "$APPEARANCE" == "light" ]]; then
        cat > "$ATUIN_OVERRIDE" << 'ATUIN_EOF'
# Atuin theme overrides - managed by catppuccin-theme-switcher
# This file overrides Nix-managed configuration

[theme]
name = "catppuccin-latte-mauve"
ATUIN_EOF
        log "   ✅ Created Atuin override for light theme (catppuccin-latte-mauve)"
    else
        cat > "$ATUIN_OVERRIDE" << 'ATUIN_EOF'
# Atuin theme overrides - managed by catppuccin-theme-switcher
# This file overrides Nix-managed configuration

[theme]
name = "catppuccin-mocha-mauve"
ATUIN_EOF
        log "   ✅ Created Atuin override for dark theme (catppuccin-mocha-mauve)"
    fi
else
    log "   🔍 Would create Atuin override for $APPEARANCE theme"
fi

# Zellij theme is now automatically managed by Nix Catppuccin module
log "🖼️  Zellij multiplexer theme: Managed by Nix Catppuccin (automatic)"

# Build detection for safe theme switching (used by Ghostty logic)
build_in_progress=false

# Primary build detection - environment variables
if [[ "${GHOSTTY_SAFE_MODE:-}" == "1" ]] || [[ "${NUSHELL_NIX_BUILD:-}" == "true" ]] || [[ -n "${NIX_BUILD_TOP:-}" ]]; then
    build_in_progress=true
fi

# Secondary build detection - active processes
if pgrep -f "nix.*build" >/dev/null 2>&1 || pgrep -f "darwin-rebuild" >/dev/null 2>&1 || pgrep -f "home-manager" >/dev/null 2>&1; then
    build_in_progress=true
fi

# Tertiary build detection - execution context
if [[ "$0" == *"home-manager-generation"* ]] || [[ "$0" == *"darwin-system"* ]] || [[ -n "${IN_NIX_SHELL:-}" ]]; then
    build_in_progress=true
fi

# Interactive session detection - if we're inside Zellij or multiplexers, be extra careful
interactive_session=false
if [[ -n "${ZELLIJ_SESSION_NAME:-}" ]] || [[ -n "${TMUX:-}" ]] || [[ "${TERM_PROGRAM:-}" == "Ghostty" ]]; then
    interactive_session=true
fi

# Update Ghostty theme
log "👻 Updating Ghostty terminal theme..."
GHOSTTY_OVERRIDES="$HOME/.config/ghostty/overrides.conf"
if [[ -f "$GHOSTTY_OVERRIDES" ]]; then
    if [[ "$APPEARANCE" == "light" ]]; then
        # Switch from dark themes to catppuccin-latte or light fallback
        if grep -q 'theme = Dracula\|theme = Catppuccin Mocha' "$GHOSTTY_OVERRIDES"; then
            if [[ "$DRY_RUN" != "true" ]]; then
                sed -i "" 's/theme = Dracula/theme = Catppuccin Latte/' "$GHOSTTY_OVERRIDES"
                sed -i "" 's/theme = Catppuccin Mocha/theme = Catppuccin Latte/' "$GHOSTTY_OVERRIDES"
            fi
            log "   ✅ Updated Ghostty theme to Catppuccin Latte (light mode)"
        elif ! grep -q 'theme = Catppuccin Latte\|theme = BlulocoLight' "$GHOSTTY_OVERRIDES"; then
            # Add light theme if no theme is set
            if [[ "$DRY_RUN" != "true" ]]; then
                echo "theme = Catppuccin Latte" >> "$GHOSTTY_OVERRIDES"
            fi
            log "   ✅ Added Ghostty theme Catppuccin Latte (light mode)"
        else
            log "   ✅ Ghostty already using a light theme"
        fi
    else
        # Switch from light themes to catppuccin-mocha or dark fallback
        if grep -q 'theme = BlulocoLight\|theme = Catppuccin Latte' "$GHOSTTY_OVERRIDES"; then
            if [[ "$DRY_RUN" != "true" ]]; then
                sed -i "" 's/theme = BlulocoLight/theme = Catppuccin Mocha/' "$GHOSTTY_OVERRIDES"
                sed -i "" 's/theme = Catppuccin Latte/theme = Catppuccin Mocha/' "$GHOSTTY_OVERRIDES"
            fi
            log "   ✅ Updated Ghostty theme to Catppuccin Mocha (dark mode)"
        elif ! grep -q 'theme = Catppuccin Mocha\|theme = Dracula' "$GHOSTTY_OVERRIDES"; then
            # Add dark theme if no theme is set
            if [[ "$DRY_RUN" != "true" ]]; then
                echo "theme = Catppuccin Mocha" >> "$GHOSTTY_OVERRIDES"
            fi
            log "   ✅ Added Ghostty theme Catppuccin Mocha (dark mode)"
        else
            log "   ✅ Ghostty already using a dark theme"
        fi
    fi
    
    # Smart Ghostty reload logic - conservative approach during builds and interactive sessions
    if [[ "$DRY_RUN" != "true" ]]; then
        # Check if we should avoid interfering with the current session
        if [[ "${GHOSTTY_SAFE_MODE:-}" == "1" ]] || [[ "$build_in_progress" == "true" ]] || [[ "$interactive_session" == "true" ]]; then
            if [[ "${GHOSTTY_SAFE_MODE:-}" == "1" ]]; then
                log "   ⚠️  Skipping Ghostty reload (ghostty safe mode active)"
            elif [[ "$build_in_progress" == "true" ]]; then
                log "   ⚠️  Skipping Ghostty reload (build in progress detected)"
            else
                log "   ⚠️  Skipping Ghostty reload (interactive session detected)"
            fi
            log "   💡 Ghostty theme changes will apply to new windows automatically"
            log "   ℹ️  For immediate effect: manually reload config (Cmd+, or keybind) when convenient"
        else
            # Only attempt reload when safe and not disruptive
            ghostty_running=$(pgrep -f Ghostty >/dev/null 2>&1 && echo "true" || echo "false")
            
            if [[ "$ghostty_running" == "true" ]]; then
                # Attempt gentle reload methods
                reload_success=false
                
                # Method 1: Try accessibility API (least disruptive)
                if osascript -e 'tell application "System Events" to tell process "Ghostty" to perform action "AXPress" of (first button whose description is "reload")' >/dev/null 2>&1; then
                    log "   🔄 Gently reloaded Ghostty configuration"
                    reload_success=true
                fi
                
                # If that failed and we're not in an interactive context, try menu method
                if [[ "$reload_success" == "false" ]] && [[ "$TERM_PROGRAM" != "Ghostty" ]]; then
                    if osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1' >/dev/null 2>&1; then
                        log "   🔄 Reloaded Ghostty configuration via menu"
                        reload_success=true
                    fi
                fi
                
                # Fallback: Just notify user
                if [[ "$reload_success" == "false" ]]; then
                    log "   💡 Ghostty is running - theme changes will apply to new windows automatically"
                    log "   ℹ️  For immediate effect: use reload_config keybind or Cmd+, when convenient"
                fi
            else
                log "   ℹ️  Ghostty not currently running - theme will apply when launched"
            fi
        fi
    else
        log "   🔄 Would attempt gentle Ghostty configuration reload"
    fi
else
    log "   ❌ Ghostty overrides file not found: $GHOSTTY_OVERRIDES"
fi

# Update shell themes
log "🐚 Updating shell theme configurations..."

# BAT theme is now automatically managed by Nix Catppuccin module

# Set shell theme environment variables
if [[ "$APPEARANCE" == "light" ]]; then
    export NUSHELL_THEME="light"
    export FISH_THEME="light"
    export ZSH_THEME="light"
else
    export NUSHELL_THEME="dark"
    export FISH_THEME="dark"
    export ZSH_THEME="dark"
fi

# Write shell theme to persistent files for new shell sessions
if [[ "$DRY_RUN" != "true" ]]; then
    echo "$NUSHELL_THEME" > "$HOME/.cache/nushell_theme" 2>/dev/null || true
    echo "$FISH_THEME" > "$HOME/.cache/fish_theme" 2>/dev/null || true
    echo "$ZSH_THEME" > "$HOME/.cache/zsh_theme" 2>/dev/null || true
fi
log "   ✅ Updated shell theme caches ($APPEARANCE mode)"

log ""
if [[ "$DRY_RUN" == "true" ]]; then
    log "🔍 DRY RUN COMPLETE - No actual changes were made"
    log "Run without --dry-run to apply these changes"
else
    log "🎉 Theme switching complete! ($CATPPUCCIN_FLAVOR mode active)"
    if [[ "$build_in_progress" == "true" ]] || [[ "$interactive_session" == "true" ]]; then
        log "💡 Current sessions preserved - new themes active for new applications"
        log "ℹ️  For immediate effect in active sessions: manually restart when convenient"
    else
        log "💡 Theme applied to all applications - restart if needed for full effect"
    fi
fi
