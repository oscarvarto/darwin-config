# Zellij Theme Management Stow Package

This stow package provides simple manual theme management for Zellij.

## Overview

The package provides a streamlined approach to Zellij theme switching with manual control only. All automatic detection and LaunchAgent complexity has been removed for simplicity.

## Components

### `~/.local/bin/zellij-theme-manager`

A simple theme management script that:
- Sets Zellij themes manually
- Updates the config file atomically
- Provides theme listing and status information
- Caches the current theme selection

## Installation

Deploy the stow package:

```bash
cd ~/darwin-config/stow
stow -t ~ zellij-theme-management
```

This will create symlinks:
- `~/.local/bin/zellij-theme-manager` → script location

## Usage

### From nushell `zt` function

The `zt` function requires explicit theme specification:

```nushell
zt catppuccin-latte         # Set light theme
zt catppuccin-macchiato     # Set dark theme
zt tokyo-night-light        # Set Tokyo Night light theme
```

### Helper functions

```nushell
zt-light                    # Shortcut for tokyo-night-light
zt-dark                     # Shortcut for catppuccin-macchiato
zt-themes                   # List available themes
zt-status                   # Show current theme status
```

### Direct usage

```bash
zellij-theme-manager set catppuccin-latte       # Set specific theme
zellij-theme-manager get                        # Get current theme
zellij-theme-manager list                       # List available themes
zellij-theme-manager status                     # Show current status
```

## How it works

1. **Manual theme setting**: When you use `zt <theme>`, it calls `zellij-theme-manager set <theme>`, which:
   - Validates the theme name
   - Updates the zellij config file immediately
   - Caches the current theme selection

## File locations

- Current theme cache: `~/.cache/zellij_current_theme`
- Zellij config: `~/.config/zellij/config.kdl`

## Troubleshooting

Check theme status:
```bash
zellij-theme-manager status
```

List available themes:
```bash
zellij-theme-manager list
```

The status command shows the current theme and config file location, making it easy to diagnose issues.
