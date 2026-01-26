# AeroSpace Stow Package

Configuration for [AeroSpace](https://github.com/nikitabobko/AeroSpace), a tiling window manager for macOS.

## Contents

- `.aerospace.toml` - Main configuration file

## Deployment

```bash
cd ~/darwin-config/stow
stow -t ~ aerospace

# Or deploy all packages
manage-stow-packages deploy
```

## Configuration Highlights

- **Layout**: Accordion mode by default with 30px padding
- **Workspaces**: 9 persistent workspaces distributed across 3 monitors
- **Key bindings**: Vim-style navigation (alt+hjkl)

### Key Bindings (Main Mode)

| Key | Action |
|-----|--------|
| `alt+h/j/k/l` | Focus left/down/up/right |
| `alt+shift+h/j/k/l` | Move window left/down/up/right |
| `alt+1-9` | Switch to workspace 1-9 |
| `alt+shift+1-9` | Move window to workspace 1-9 |
| `alt+tab` | Switch to previous workspace |
| `alt+shift+tab` | Move workspace to next monitor |
| `alt+/` | Toggle tiles layout |
| `alt+,` | Toggle accordion layout |
| `alt+-/=` | Resize window |
| `alt+shift+0` | Enter service mode |

### Service Mode (`alt+shift+0`)

| Key | Action |
|-----|--------|
| `esc` | Reload config and exit |
| `r` | Reset (flatten) workspace layout |
| `f` | Toggle floating/tiling |
| `backspace` | Close all windows except current |
| `alt+shift+h/j/k/l` | Join with adjacent window |

## Customization

Edit `~/darwin-config/stow/aerospace/.aerospace.toml` and restow:

```bash
cd ~/darwin-config/stow
stow -R -t ~ aerospace
```

See [AeroSpace documentation](https://nikitabobko.github.io/AeroSpace/guide) for all configuration options.
