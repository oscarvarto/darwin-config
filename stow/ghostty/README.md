# Ghostty Stow Package

This package manages Ghostty terminal emulator configuration overrides.

## Contents

- `.config/ghostty/overrides.conf` - Ghostty configuration overrides

## Installation

```bash
cd ~/darwin-config/stow
stow -t ~ ghostty
```

Or use the stow package manager:

```bash
manage-stow-packages deploy
```

## Configuration

The `overrides.conf` file contains personal preferences that override the base Ghostty configuration:

- **Font**: MonoLisa Variable Nerd Font at 16pt with thickening
- **Theme**: Catppuccin Mocha
- **Scrollback**: Large buffer (900M lines)
- **Terminal**: xterm-ghostty terminfo

## Customization

Edit the source file at `~/darwin-config/stow/ghostty/.config/ghostty/overrides.conf` and re-run stow to apply changes.
