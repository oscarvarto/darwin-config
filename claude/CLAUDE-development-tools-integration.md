# Development Tools Integration

### Editor Configurations (via Stow)
- **Emacs**: Provided via `emacs-overlay` with Liquid Glass icons applied during build
  - Now uses Emacs from Nix packages with home-manager service
  - Removed Scala support, focused on core languages
  - Enhanced terminal compatibility (Ghostty support)
- **LazyVim**: `stow/lazyvim/` - Modern Neovim setup with Lisp/Elisp support
  - Added `lisp.lua` and `elisp.lua` plugins for Lisp editing
  - Parinfer support for structural editing
- Font cycling with F8, LSP support, AI integration
- Emacs service managed by home-manager with proper daemon support

### Tool Management Scripts (via Stow)
- `manage-cargo-tools install` - Rust tools from cargo-tools.toml
- `manage-nodejs-tools install` - Node.js toolchain from nodejs-tools.toml  
- `manage-dotnet-tools install` - .NET SDK from dotnet-tools.toml
- `manage-stow-packages deploy` - Deploy all stow configurations

### Development Utilities
- `cleanup-intellij [project]` - Clean IntelliJ IDEA caches and state
- Git configurations with conditional includes
- Enhanced shell functions and aliases
