# Essential Build Commands

### Core Development Workflow
- `nb` - Build darwin configuration (preferred alias for `nix run .#build`)
- `ns` - Build and switch to new configuration (preferred alias for `nix run .#build-switch`)
- `./apps/aarch64-darwin/build` - Direct build script (Apple Silicon)
- `./apps/aarch64-darwin/build-switch` - Direct build and switch script
- `./apps/aarch64-darwin/rollback` - Rollback to previous generation
- `nix run .#apply` - Apply user/secrets repo placeholders into files

### Emacs Management
- `build-emacs-priority [--continue-build]` - Build the emacs-overlay `emacs-git` derivation with dedicated resources
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
