# Kitty Terminal Configuration Package

This stow package provides a complete, automated setup for the Kitty terminal emulator with optimized configuration for macOS.

## Features

- **Font Configuration**: MonoLisaVariable Nerd Font at size 18 with ligatures
- **Theme Management**: Catppuccin Latte (light) and Mocha (dark) with automatic switching
- **Terminfo Setup**: Proper terminal compatibility for applications like emacsclient
- **Performance Optimization**: macOS-specific rendering optimizations
- **Automation Scripts**: Complete setup and maintenance tools

## Prerequisites

1. **Kitty Installation**: Install via Homebrew cask
   ```bash
   brew install --cask kitty
   ```

2. **MonoLisaVariable Nerd Font** (recommended): Install the font files to `~/Library/Fonts/`

## Installation

### Option 1: Automated Deployment (Recommended)

1. **Use the smart deployment script**:
   ```bash
   deploy-kitty-stow
   ```
   This script handles conflicts with existing files automatically.

2. **Run the complete setup**:
   ```bash
   setup-kitty-complete
   ```

### Option 2: Manual Deployment

1. **If you have existing kitty config files, choose one:**

   **Adopt existing files (recommended if you have customizations):**
   ```bash
   cd ~/darwin-config/stow
   stow --adopt -t ~ kitty
   ```

   **Or backup existing files:**
   ```bash
   mkdir ~/.kitty-backup
   mv ~/.config/kitty ~/.kitty-backup/
   mv ~/.local/share/bin/kitty-* ~/.kitty-backup/ 2>/dev/null || true
   stow -t ~ kitty
   ```

2. **Run the complete setup**:
   ```bash
   setup-kitty-complete
   ```

## Manual Setup Steps

If you prefer to run setup components individually:

1. **Install terminfo**:
   ```bash
   setup-kitty-terminfo
   ```

2. **Setup themes**:
   ```bash
   setup-kitty-themes
   ```

3. **Test configuration**:
   ```bash
   test-kitty-font
   ```

## Configuration Files

- `~/.config/kitty/kitty.conf` - Main configuration file
- `~/.config/kitty/current-theme.conf` - Active theme (Catppuccin Latte)

## Available Commands

### Theme Management
- `kitty-light` - Switch to Catppuccin Latte (light theme)
- `kitty-dark` - Switch to Catppuccin Mocha (dark theme)
- `kitty-theme-switcher` - Automatic light/dark switching based on system appearance
- `kitty +kitten themes` - Interactive theme selector

### Testing and Maintenance
- `test-kitty-font` - Verify font configuration and rendering
- `setup-kitty-complete` - Re-run complete setup
- `setup-kitty-terminfo` - Re-install terminfo only
- `setup-kitty-themes` - Re-setup themes only

## Key Configuration Features

### macOS Window Behavior
To ensure Kitty fully quits when the last tab/window is closed (so the app exits instead of remaining in the dock with no windows), this config enables:

```
macos_quit_when_last_window_closed yes
confirm_os_window_close 0
```

Close all tabs in the last window and the Kitty app will exit automatically without a confirmation prompt.

### Font Settings
```
font_family MonoLisaVariable Nerd Font Regular
font_size 18.0
disable_ligatures never
font_features MonoLisaVariableNF-Regular +liga +calt
```

### Performance Optimizations
```
macos_thicken_font 0.75
repaint_delay 10
input_delay 3
sync_to_monitor yes
```

### Theme Integration
- Default: Catppuccin Latte (light)
- Dark mode: Catppuccin Mocha
- Automatic switching based on macOS system appearance

## Troubleshooting

### Font Issues
- Run `fc-list | grep -i monolisa` to verify font installation
- Check `test-kitty-font` output for proper zero character rendering
- Ensure font files are in `~/Library/Fonts/`

### Terminfo Issues
- Run `infocmp xterm-kitty` to verify terminfo installation
- Re-run `setup-kitty-terminfo` if needed
- Check that emacsclient works: `TERM=xterm-kitty emacsclient --version`

### Theme Issues
- Use `kitty +kitten themes` for interactive theme selection
- Check that `~/.config/kitty/current-theme.conf` exists
- Run `setup-kitty-themes` to reset theme configuration

## Removal

To remove the kitty configuration:

```bash
stow -D -t ~ kitty
rm -rf ~/.config/kitty
rm ~/.local/share/bin/kitty-* ~/.local/share/bin/setup-kitty-* ~/.local/share/bin/test-kitty-font
```

## Integration with darwin-config

This package is designed to work with the darwin-config nix setup where:
- Kitty is installed via `modules/casks.nix`
- Home-manager kitty configuration is disabled
- Font management is handled separately

The package automates the manual configuration that would otherwise need to be repeated on each new system setup.
