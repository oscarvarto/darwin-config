# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive macOS system configuration using Nix-Darwin and Home Manager with flakes. The repository configures an entire macOS development environment including packages, applications, shell configurations, editors, and secrets management.

**Current Branch**: feature/emacs - Enhanced Emacs integration with home-manager service, version pinning, and improved macOS support.

## Essential Build Commands

### Core Development Workflow
- `nb` - Build darwin configuration (preferred alias for `nix run .#build`)
- `ns` - Build and switch to new configuration (preferred alias for `nix run .#build-switch`)
- `./apps/aarch64-darwin/build` - Direct build script (Apple Silicon)
- `./apps/aarch64-darwin/build-switch` - Direct build and switch script
- `./apps/aarch64-darwin/rollback` - Rollback to previous generation
- `nix run .#apply` - Apply user/secrets repo placeholders into files

### Emacs Management (NEW in feature/emacs)
- `emacs-pin [commit]` - Pin Emacs to specific commit or current version
- `emacs-unpin` - Unpin Emacs to use latest from overlay
- `emacs-pin-diff` - Show differences between pinned and latest Emacs
- `emacs-pin-status` - Show current Emacs pinning status
- `emacs-service-toggle` - Toggle Emacs home-manager service on/off
- `emacsclient-gui` - Launch Emacs GUI with proper macOS integration

### Validation & Development
- `nix flake check` - Validate flake configuration and evaluate checks
- `nix fmt .` - Format Nix files
- `nix develop` - Enter development shell (sets EDITOR=nvim, provides git, bash)
- `smart-gc clean` - Cleanup old generations (keeps last 3)
- `smart-gc status` - Check system status and disk usage

### Configuration Management
- `nix run .#add-host -- --hostname HOST --user USER` - Add new host to flake
- `nix run .#configure-user -- --user USER --hostname HOST` - Configure for specific user/hostname
- `nix run .#update-doom-config` - Update Doom Emacs configuration

### SSH Keys and Basic Secrets
- `./apps/aarch64-darwin/check-keys` - Check if required SSH keys exist
- `./apps/aarch64-darwin/create-keys` - Create SSH keys (id_ed25519, id_ed25519_agenix)
- `./apps/aarch64-darwin/copy-keys` - Copy SSH keys from mounted USB to ~/.ssh

### Enhanced Secret Management (Unified CLI)
- `secret status` - Show status of all credential systems
- `secret list` - List available agenix secrets
- `secret create <name>` - Create new agenix secret
- `secret edit <name>` - Edit existing agenix secret
- `secret show <name>` - Display decrypted secret content
- `secret rekey` - Re-encrypt all agenix secrets with current keys
- `secret sync-git` - Update git configs from 1Password/pass credentials
- `secret op-get <item>` - Get 1Password item
- `secret pass-get <path>` - Get pass entry
- `backup-secrets` - Backup all secrets, keys, and configurations
- `setup-secrets-repo` - Clone and setup secrets repository

### Font Management
- `detect-fonts status` - Show availability of programming fonts
- `detect-fonts emacs-font` - Get recommended font key for Emacs
- `detect-fonts ghostty-font` - Get recommended font name for terminals
- `ghostty-config font "Font Name"` - Switch terminal font

### GNU Stow Package Management
- `manage-stow-packages deploy` - Deploy all stow packages
- `manage-stow-packages remove` - Remove all stow packages
- `stow -t ~ PACKAGE` - Deploy specific package (**CRITICAL**: -t ~ target flag is REQUIRED)
- `stow -D -t ~ PACKAGE` - Remove specific package (**CRITICAL**: always include -t ~ flag)
- `manage-cargo-tools install` - Install Rust/Cargo tools from cargo-tools.toml
- `manage-nodejs-tools install` - Install Node.js toolchain from nodejs-tools.toml
- `manage-dotnet-tools install` - Install .NET SDK and tools from dotnet-tools.toml

## Code Architecture

### Primary Structure
```
flake.nix                     # Main flake with host configurations
system.nix                    # System-level macOS configuration  
modules/                      # Modular configuration components
├── home-manager.nix          # User environment & Home Manager config
├── packages.nix              # Nix packages (CLI tools, dev tools)
├── casks.nix                 # Homebrew casks (GUI applications)
├── brews.nix                 # Homebrew formulas (additional CLI)
├── path-config.nix           # Centralized PATH management
├── secrets.nix               # Age-encrypted secrets with agenix
├── enhanced-secrets.nix      # Unified secret management CLI
├── secure-credentials.nix    # 1Password/pass integration
├── emacs-pinning.nix         # Emacs version pinning system (NEW)
├── terminal-support.nix      # Ghostty terminfo support (NEW)
├── biometric-auth.nix        # macOS biometric authentication (NEW)
├── starship.toml             # Starship prompt with Catppuccin theme
└── [various other modules]
```

### Multi-User/Multi-Host Design
- Host configurations defined in `flake.nix` `hostConfigs` section
- Each host specifies: user, system architecture, defaultShell, hostSettings
- Supports personal/work profiles with conditional configuration
- Shell choice per host: "nushell" or "zsh"

### Configuration Layer Structure
1. **System Layer** (`system.nix`) - macOS system settings, services
2. **Package Layer** (`modules/packages.nix`) - Nix packages
3. **Application Layer** (`modules/casks.nix`, `brews.nix`) - GUI apps via Homebrew  
4. **User Layer** (`modules/home-manager.nix`) - User environment, dotfiles
5. **Stow Layer** (`stow/`) - Complex configurations (editors, scripts)

## Key Architectural Patterns

### Secrets Management (Multi-Layer)
- **agenix**: SSH keys, certificates, system secrets (encrypted with age)
- **1Password**: User credentials, API tokens (enterprise-grade auth)
- **pass**: Backup credential store (offline, GPG-encrypted)
- **Unified CLI**: Single `secret` command for all credential systems

### PATH Management (Centralized)
- All PATH configuration in `modules/path-config.nix`
- Overrides mise, homebrew, and other tools
- Consistent across both shells (zsh, nushell)
- Priority-ordered entries with automatic deduplication

### Font System (Intelligent Fallback)
- **Font detection**: Uses `fc-list` for accurate family name matching
- **Preference hierarchy**: MonoLisa Variable → PragmataPro Liga → JetBrains Mono → system fonts
- **Emacs integration**: F8 key cycles through fonts (preserving existing functionality)
- **Terminal integration**: Ghostty includes font fallback chain in base configuration
- **Open-source fallback**: JetBrains Mono provided via Nix packages (jetbrains-mono)
- **Optimized settings**: Each font includes ligature configuration and optimal sizes
- **Graceful degradation**: Missing commercial fonts don't break applications

### Shell Configuration (Multi-Shell Support)
- Supports nushell and zsh with feature parity
- Shared aliases, PATH, development tools across both shells
- Shell-specific strengths preserved (nushell data processing, zsh compatibility)
- Consistent Starship prompts, Zoxide navigation, Atuin history
- Note: Fish shell binary is installed only as a completion engine for Nushell

## Development Tools Integration

### Editor Configurations (via Stow)
- **Doom Emacs**: `stow/doom-emacs/` - Complete modular configuration
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
- Git configurations with conditional work/personal configs
- Enhanced shell functions and aliases

## Testing & Validation

**There is no traditional test suite in this repository.** Instead, validation occurs through:

### Build Testing
- `nix flake check` - Validates all flake outputs and configurations
- `nix run .#build` - Tests that configuration builds successfully
- Configuration scripts include `--dry-run` modes for safe testing

### Configuration Validation
- Scripts validate host configs exist before applying
- Automatic rollback on build failures
- Syntax validation for complex configurations (Doom Emacs elisp)

## Important Implementation Notes

### Multi-User Adaptation
- Add new hosts via `nix run .#add-host`
- Host-specific settings in `flake.nix` `hostConfigs`
- Work/personal profiles affect git configs, directory structures

### Secrets Workflow
- System secrets managed via agenix (encrypted in git)
- User credentials via 1Password/pass (not stored in git)
- `secret` command provides unified interface
- Automatic git credential synchronization

### Stow Package Management (**CRITICAL USAGE PATTERNS**)
- Complex configurations managed via GNU Stow
- Symlinks from `stow/package-name/` to home directory
- **CRITICAL**: Always use `stow -t ~` syntax - the target directory flag is REQUIRED
- **CRITICAL**: Use `manage-stow-packages` command (not manage-aux-scripts)
- Use for editors, scripts, tool configurations that are difficult to embed in Nix
- Package structure mirrors home directory layout for automatic placement
- Most scripts symlinked to `~/.local/share/bin`
- **NEW**: Enhanced Emacs service scripts in `stow/nix-scripts/`

### PATH Override Strategy
- `modules/path-config.nix` takes absolute precedence
- Add custom paths at top of `pathEntries` list
- Rebuild with `ns` to apply changes
- Overrides mise, homebrew, system defaults

## Common Patterns

### Adding New Software
1. Check if available as Nix package (`modules/packages.nix`)
2. If GUI app, add to Homebrew casks (`modules/casks.nix`)
3. If CLI tool, add to Homebrew brews (`modules/brews.nix`)
4. Rebuild with `nb && ns`

### Managing Emacs Versions
1. Pin to current: `emacs-pin` (no args)
2. Pin to specific: `emacs-pin abc123def`
3. Check status: `emacs-pin-status`
4. Unpin for latest: `emacs-unpin`
5. Rebuild: `nb && ns`

### Adding New Host/User
1. `nix run .#add-host -- --hostname HOST --user USER`
2. Configure host-specific settings in generated config
3. Test with `nix run .#configure-user -- --dry-run`
4. Apply with `nix run .#configure-user`

### Shell Customization
1. Edit appropriate shell config in `modules/`
2. Add aliases/functions to shell-specific sections
3. PATH changes go in `modules/path-config.nix`
4. Rebuild with `ns`

## Security Considerations

- Secrets are encrypted at rest (agenix) or stored securely (1Password/pass)
- SSH keys managed separately from repository
- Work/personal credential isolation
- Automatic sensitive data sanitization scripts available