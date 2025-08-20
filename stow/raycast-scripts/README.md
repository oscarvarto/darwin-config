# Raycast Scripts for Yabai Window Management

This directory contains Raycast scripts that replace the previous skhd configuration for window management with yabai.

## Scripts Available

### Parameterized Scripts
- `yabai-focus-space.sh` - Switch to any desktop space (1-10)
- `yabai-move-window-to-space.sh` - Move current window to any space and follow (1-10)

### Utility Scripts
- `yabai-toggle-fullscreen.sh` - Toggle native fullscreen for current window
- `yabai-restart-service.sh` - Restart the yabai service
- `yabai-start-service.sh` - Start the yabai service
- `yabai-stop-service.sh` - Stop the yabai service

## Installation

Scripts are deployed using stow:

```bash
cd ~/darwin-config/stow
stow -t ~ raycast-scripts
```

This creates symlinks in `~/.local/share/bin/` pointing to the scripts in this directory.

## Raycast Setup

1. Open Raycast
2. Go to Extensions tab
3. Click '+' to add a new extension
4. Select 'Add Script Commands'
5. Browse to: `~/.local/share/bin`
6. Click 'Add'

## Usage

The parameterized scripts (focus-space and move-window-to-space) will prompt for a space number when invoked from Raycast.

You can also set up Raycast hotkeys for frequently used combinations.
