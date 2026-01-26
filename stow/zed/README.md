# Zed Configuration

This stow package contains my Zed editor configuration with optimized settings for development.

## Installation

To install this configuration, run:

```bash
cd ~/darwin-config/stow
stow -t ~ zed
```

## Removal

To remove this configuration, run:

```bash
cd ~/darwin-config/stow
stow -D -t ~ zed
```

## What's included

- `settings.json` - Main Zed configuration with themes, fonts, and LSP settings
- `settings.local.json` - Local-only overrides (not tracked). Use for API keys.
- `settings.local.jsonc.example` - Template for local overrides
- `keymap.json` - Custom key bindings and shortcuts
- `tasks.json` - Build tasks and custom commands

## Key Features

### Development Environment
- **Xcode Beta Integration**: Configured to use Xcode 26.0 beta toolchain
- **Multiple Language Support**: Swift, C/C++, Rust, Python, Java with LSP
- **Vi Mode**: Enabled for efficient text editing
- **Intelligent Completion**: Copilot and Zed AI integration

### UI/UX
- **Fonts**: MonoLisaVariable and PragmataPro Liga with proper sizing
- **Theme**: Catppuccin Mocha/Latte with system theme switching
- **Terminal**: Integrated Nushell terminal with proper font configuration
- **Visual Aids**: Indent guides and inlay hints enabled

### Language Server Configuration
- **clangd**: Configured for C/C++ development using Xcode beta
- **SourceKit LSP**: Swift development with latest toolchain
- **jdtls**: Java development with Lombok support
;; Scala LSP support removed
- **pyrefly**: Python development with custom configuration

## Notes

- Configuration is stored at `~/.config/zed/` when stowed
- LSP servers are configured to use appropriate toolchains (Xcode beta for C/Swift)
- Terminal integration uses Nushell as the default shell
- Font fallback system ensures proper display across different systems

## Dependencies

- Zed editor (installed via Homebrew casks)
- Xcode beta (for C/C++/Swift development)
- Various language servers (installed via respective package managers)
- Nushell (configured as terminal shell)

## Customization

The configuration is optimized for:
- macOS development workflow
- Multi-language projects
- Catppuccin color scheme
- High-resolution displays with appropriate font sizing

### Local secrets (safe)
Put API keys in `~/.config/zed/settings.local.json` and keep that file untracked.
You can copy the template:

```bash
cp ~/darwin-config/stow/zed/.config/zed/settings.local.jsonc.example ~/.config/zed/settings.local.json
```
