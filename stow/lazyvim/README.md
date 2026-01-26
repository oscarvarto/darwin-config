# LazyVim Configuration

This stow package contains my Neovim configuration based on LazyVim.

## Installation

To install this configuration, run:

```bash
cd ~/darwin-config/stow
stow lazyvim
```

## Removal

To remove this configuration, run:

```bash
cd ~/darwin-config/stow
stow -D lazyvim
```

## What's included

- LazyVim configuration files
- Custom lua configurations
- Plugin settings and overrides
- Lazy lock file for reproducible plugin versions

## Notes

- This configuration requires Neovim 0.8+ (installed via nix)
- LazyVim will handle plugin installation automatically on first run
- Configuration is stored at `~/.config/nvim/` when stowed
