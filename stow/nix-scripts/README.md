# Nix Scripts

This stow package contains various utility scripts extracted from the nix configuration to simplify maintenance and avoid complex string escaping.

## Scripts Included

### Nix Cleanup Scripts (Nushell)
- `smart-gc.nu` - Smart garbage collection with generation preservation and essential package pinning
- `nix-cleanup.nu` - Main cleanup script with multiple modes
- `nix-quick-clean.nu` - Quick cleanup (keep last 5 generations)
- `nix-auto-cleanup.nu` - Automated cleanup for periodic maintenance

### Ghostty Configuration Scripts (Nushell)
- `ghostty-config.nu` - Main configuration helper
- `ghostty-font-monolisa.nu` - Switch to MonoLisa font
- `ghostty-font-pragmata.nu` - Switch to PragmataPro font
- `ghostty-theme-dark.nu` - Switch to dark theme
- `ghostty-theme-light.nu` - Switch to light theme
- `ghostty-shell-fish.nu` - Switch to fish shell
- `ghostty-shell-zsh.nu` - Switch to zsh shell
- `ghostty-shell-bash.nu` - Switch to bash shell
- `ghostty-shell-nushell.nu` - Switch to nushell
- `ghostty-shell-pwsh.nu` - Switch to PowerShell

### Raycast Scripts (Bash)
- `delete_clipboard.sh` - Clear macOS clipboard
- `emacsclient` - Launch Emacs via daemon

## Installation

Use stow to symlink these scripts:

```bash
cd ~/darwin-config/stow
stow nix-scripts
```

## Features

- **Unicode/Emoji Support**: Scripts now use actual Unicode characters instead of escaped sequences
- **Simplified Maintenance**: No complex string escaping required
- **Nushell Benefits**: Better error handling, structured data, and modern shell features
- **Raycast Integration**: Bash scripts maintain compatibility with Raycast requirements

## Usage Examples

```bash
# Nix cleanup
nix-cleanup.nu status
nix-cleanup.nu quick --dry-run
nix-cleanup.nu custom 7

# Ghostty configuration
ghostty-config.nu font "JetBrains Mono" 16
ghostty-config.nu theme nord
ghostty-config.nu shell fish
```
