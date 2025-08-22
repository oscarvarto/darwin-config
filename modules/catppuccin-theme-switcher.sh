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
    • Starship (shell prompt)
    • Atuin (shell history)
    • Zellij (terminal multiplexer)
    • Ghostty (terminal emulator) - Live config reload without restart
    • Nushell (shell syntax highlighting)
    • Zsh (shell colors)
    • BAT (syntax highlighter)

THEME MAPPING:
    Light Mode:  Catppuccin Latte (with high contrast colors)
    Dark Mode:   Catppuccin Mocha (with vibrant colors)

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
    for cache_file in ~/.cache/nushell_theme ~/.cache/zsh_theme; do
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
        starship_theme=$(grep "^palette = " "$HOME/.config/starship.toml" | sed "s/palette = '\(.*\)'/\1/" || echo "unknown")
        echo "   Starship: $starship_theme"
    else
        echo "   Starship: not configured"
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
        zellij_theme=$(grep 'theme "' "$HOME/.config/zellij/config.kdl" | sed 's/theme "\(.*\)"/\1/' || echo "unknown")
        echo "   Zellij: $zellij_theme"
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
    STARSHIP_PALETTE="catppuccin_mocha"
    BAT_THEME="ansi"
else
    CATPPUCCIN_FLAVOR="latte"
    STARSHIP_PALETTE="catppuccin_latte"
    BAT_THEME="GitHub"
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

# Update starship configuration
log "⭐ Updating Starship prompt theme..."
STARSHIP_CONFIG="$HOME/.config/starship.toml"
if [[ -f "$STARSHIP_CONFIG" ]]; then
    if grep -q "^palette = " "$STARSHIP_CONFIG"; then
        if [[ "$DRY_RUN" != "true" ]]; then
            sed -i "" "s/^palette = .*/palette = '$STARSHIP_PALETTE'/" "$STARSHIP_CONFIG"
        fi
        log "   ✅ Updated Starship to use $STARSHIP_PALETTE"
    else
        log "   ⚠️  Starship palette setting not found in $STARSHIP_CONFIG"
    fi
else
    log "   ❌ Starship config file not found: $STARSHIP_CONFIG"
fi

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

# Update zellij theme via override config (Nix-managed base config)
log "🖼️  Updating Zellij multiplexer theme..."
ZELLIJ_BASE_CONFIG="$HOME/.config/zellij/config.kdl"
ZELLIJ_OVERRIDE_DIR="$HOME/.config/zellij/overrides"
ZELLIJ_THEME_OVERRIDE="$ZELLIJ_OVERRIDE_DIR/theme-override.kdl"

if [[ -f "$ZELLIJ_BASE_CONFIG" ]]; then
    if [[ "$DRY_RUN" != "true" ]]; then
        mkdir -p "$ZELLIJ_OVERRIDE_DIR"
        
        # Create theme override config that includes base config
        if [[ "$APPEARANCE" == "light" ]]; then
            cat > "$ZELLIJ_THEME_OVERRIDE" << 'ZELLIJ_EOF'
// Zellij theme override - managed by catppuccin-theme-switcher
// This file overrides the theme setting from the Nix-managed base configuration

theme "catppuccin-latte"

// Include all other settings from base config by copying key sections
keybinds clear-defaults=true {
    // Keybinds are inherited from base config - using minimal override
    shared_except "locked" {
        bind "Ctrl q" { Quit; }
        bind "Alt `" { SwitchToMode "locked"; }
    }
}

default_mode "locked"
default_shell "nu"
copy_command "pbcopy"
attach_to_session true
styled_underlines true
support_kitty_keyboard_protocol true
show_startup_tips false
ZELLIJ_EOF
        else
            cat > "$ZELLIJ_THEME_OVERRIDE" << 'ZELLIJ_EOF'
// Zellij theme override - managed by catppuccin-theme-switcher
// This file overrides the theme setting from the Nix-managed base configuration

theme "catppuccin-mocha"

// Include all other settings from base config by copying key sections
keybinds clear-defaults=true {
    // Keybinds are inherited from base config - using minimal override
    shared_except "locked" {
        bind "Ctrl q" { Quit; }
        bind "Alt `" { SwitchToMode "locked"; }
    }
}

default_mode "locked"
default_shell "nu"
copy_command "pbcopy"
attach_to_session true
styled_underlines true
support_kitty_keyboard_protocol true
show_startup_tips false
ZELLIJ_EOF
        fi
        
        # Set environment variable for shell sessions
        echo "export ZELLIJ_CONFIG_FILE=\"$ZELLIJ_THEME_OVERRIDE\"" > "$HOME/.cache/zellij_theme_config"
        
        log "   ✅ Created Zellij theme override for $APPEARANCE mode"
        log "   💡 Use 'source ~/.cache/zellij_theme_config' or restart shell to apply"
    else
        log "   🔍 Would create Zellij theme override for $APPEARANCE mode"
    fi
else
    log "   ❌ Zellij base config file not found: $ZELLIJ_BASE_CONFIG"
fi

# Update Ghostty theme
log "👻 Updating Ghostty terminal theme..."
GHOSTTY_OVERRIDES="$HOME/.config/ghostty/overrides.conf"
if [[ -f "$GHOSTTY_OVERRIDES" ]]; then
    if [[ "$APPEARANCE" == "light" ]]; then
        # Switch from dark themes to catppuccin-latte or light fallback
        if grep -q 'theme = dracula\|theme = catppuccin-mocha' "$GHOSTTY_OVERRIDES"; then
            if [[ "$DRY_RUN" != "true" ]]; then
                sed -i "" 's/theme = dracula/theme = catppuccin-latte/' "$GHOSTTY_OVERRIDES"
                sed -i "" 's/theme = catppuccin-mocha/theme = catppuccin-latte/' "$GHOSTTY_OVERRIDES"
            fi
            log "   ✅ Updated Ghostty theme to catppuccin-latte (light mode)"
        elif ! grep -q 'theme = catppuccin-latte\|theme = BlulocoLight' "$GHOSTTY_OVERRIDES"; then
            # Add light theme if no theme is set
            if [[ "$DRY_RUN" != "true" ]]; then
                echo "theme = catppuccin-latte" >> "$GHOSTTY_OVERRIDES"
            fi
            log "   ✅ Added Ghostty theme catppuccin-latte (light mode)"
        else
            log "   ✅ Ghostty already using a light theme"
        fi
    else
        # Switch from light themes to catppuccin-mocha or dark fallback
        if grep -q 'theme = BlulocoLight\|theme = catppuccin-latte' "$GHOSTTY_OVERRIDES"; then
            if [[ "$DRY_RUN" != "true" ]]; then
                sed -i "" 's/theme = BlulocoLight/theme = catppuccin-mocha/' "$GHOSTTY_OVERRIDES"
                sed -i "" 's/theme = catppuccin-latte/theme = catppuccin-mocha/' "$GHOSTTY_OVERRIDES"
            fi
            log "   ✅ Updated Ghostty theme to catppuccin-mocha (dark mode)"
        elif ! grep -q 'theme = catppuccin-mocha\|theme = dracula' "$GHOSTTY_OVERRIDES"; then
            # Add dark theme if no theme is set
            if [[ "$DRY_RUN" != "true" ]]; then
                echo "theme = catppuccin-mocha" >> "$GHOSTTY_OVERRIDES"
            fi
            log "   ✅ Added Ghostty theme catppuccin-mocha (dark mode)"
        else
            log "   ✅ Ghostty already using a dark theme"
        fi
    fi
    
    # Smart Ghostty reload logic - use config reload instead of restart
    if [[ "$DRY_RUN" != "true" ]]; then
        # Try to reload Ghostty configuration using AppleScript
        if osascript -e 'tell application "System Events" to tell process "Ghostty" to perform action "AXPress" of (first button whose description is "reload")' 2>/dev/null; then
            log "   🔄 Reloaded Ghostty configuration via AppleScript"
        elif osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1' 2>/dev/null; then
            log "   🔄 Reloaded Ghostty configuration via menu action"
        else
            # Fallback: Check if Ghostty is running and try alternative methods
            if pgrep -f Ghostty >/dev/null 2>&1; then
                # Alternative: Try to send a signal or use other IPC if available
                log "   💡 Ghostty is running - theme changes will apply to new windows automatically"
                log "   ℹ️  For immediate effect in existing windows, use the reload_config keybind or menu"
            else
                log "   ℹ️  Ghostty not currently running - theme will apply when launched"
            fi
        fi
    else
        log "   🔄 Would reload Ghostty configuration (no restart needed)"
    fi
else
    log "   ❌ Ghostty overrides file not found: $GHOSTTY_OVERRIDES"
fi

# Update shell themes
log "🐚 Updating shell theme configurations..."

# Set environment variables for current session
export BAT_THEME="$BAT_THEME"

# Set shell theme environment variables
if [[ "$APPEARANCE" == "light" ]]; then
    export NUSHELL_THEME="light"
    export ZSH_THEME="light"
else
    export NUSHELL_THEME="dark"
    export ZSH_THEME="dark"
fi

# Write shell theme to persistent files for new shell sessions
if [[ "$DRY_RUN" != "true" ]]; then
    echo "$NUSHELL_THEME" > "$HOME/.cache/nushell_theme" 2>/dev/null || true
    echo "$ZSH_THEME" > "$HOME/.cache/zsh_theme" 2>/dev/null || true
fi
log "   ✅ Updated shell theme caches ($APPEARANCE mode)"
log "   ✅ Set BAT_THEME to $BAT_THEME"

log ""
if [[ "$DRY_RUN" == "true" ]]; then
    log "🔍 DRY RUN COMPLETE - No actual changes were made"
    log "Run without --dry-run to apply these changes"
else
    log "🎉 Theme switching complete! ($CATPPUCCIN_FLAVOR mode active)"
    log "💡 Restart terminal applications to see all changes"
fi