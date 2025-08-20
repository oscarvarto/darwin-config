# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

- Repository: darwin-config (macOS system configuration managed with Nix flakes)
- Primary focus: macOS workflows for both aarch64-darwin (Apple Silicon) and x86_64-darwin (Intel)
- Single-user repository design with multi-user adaptation capabilities

Common commands (macOS aarch64-darwin)
- Preferred aliases
  - nb  # Build the nix configuration (user-defined alias)
  - ns  # Build and switch to the new configuration (user-defined alias)
  - Use these where possible; see below for script equivalents.

- Build and switch (script apps)
  - Build and switch: ./apps/aarch64-darwin/build-switch
  - Build only (no switch): ./apps/aarch64-darwin/build
  - Roll back to a previous generation: ./apps/aarch64-darwin/rollback

- Validate and format
  - Validate flake and evaluate checks: nix flake check
  - Format Nix files: nix fmt .

- Dev shell
  - Enter repo dev shell (sets EDITOR, provides git, bash): nix develop

- Secrets and SSH keys helpers (macOS)
  - Check required keys exist: ./apps/aarch64-darwin/check-keys
  - Create keys (id_ed25519, id_ed25519_agenix): ./apps/aarch64-darwin/create-keys
  - Copy keys from mounted USB to ~/.ssh: ./apps/aarch64-darwin/copy-keys
  - Apply user/secrets repo placeholders into files: ./apps/aarch64-darwin/apply

- Enhanced secret management (unified CLI)
  - secret status           # Show status of all credential systems
  - secret list            # List available agenix secrets
  - secret create <name>   # Create new agenix secret
  - secret edit <name>     # Edit existing agenix secret
  - secret show <name>     # Display decrypted secret content
  - secret rekey           # Re-encrypt all agenix secrets with current keys
  - secret sync-git        # Update git configs from 1Password/pass credentials
  - secret op-get <item>   # Get 1Password item
  - secret pass-get <path> # Get pass entry
  - backup-secrets         # Backup all secrets, keys, and configurations
  - setup-secrets-repo     # Clone and setup secrets repository

Notes
- There is no traditional test suite in this repo; use nix flake check for validation.
- Many developer scripts are managed via stow and symlinked to ~/.local/share/bin (see stow/README.md).

High-level architecture
- Flake inputs (key ones)
  - nixpkgs (unstable), darwin (nix-darwin), home-manager
  - nix-homebrew and taps (homebrew-core, -cask, -bundle, emacs-plus)
  - agenix (secrets), disko (NixOS disks), catppuccin (theming), neovim-nightly overlay, op-shell-plugins, a non-flake GitHub secrets repo

- Flake outputs
  - devShells: per-system shells (default shell includes git and sets EDITOR=nvim)
  - apps: System-specific CLI entrypoints that execute scripts under apps/<system>/ (e.g., build, build-switch, check-keys, create-keys, copy-keys, rollback, apply, configure-user, add-host, setup-secrets, etc.)
  - darwinConfigurations: Built via mkDarwinConfig for each hostname in hostConfigs
    - Modules include: home-manager.darwinModules.home-manager, agenix.darwinModules.default, and local modules from ./modules/
    - Host named predator is explicitly defined for aarch64-darwin with user "oscarvarto"
    - Each host configuration supports custom user, system, defaultShell, and hostSettings

- Modules layout (actual structure)
  - modules/ (macOS-focused configuration modules)
    - home-manager.nix: user programs and home-manager configuration
    - packages.nix: Nix packages for macOS
    - casks.nix: Homebrew casks (GUI applications)
    - brews.nix: Homebrew formulas (CLI tools)
    - secrets.nix: agenix-encrypted secrets configuration
    - secure-credentials.nix: 1Password/pass integration for git credentials
    - enhanced-secrets.nix: unified secret management CLI tools
    - files.nix: immutable non-Nix files
    - overlays.nix: Nix package overlays
    - shell-config.nix: shell configuration and aliases
    - zsh-darwin.nix: Zsh shell configuration
    - dock/: macOS Dock configuration
    - nushell/: Nushell shell configuration
    - scripts/nu/: Nushell utility scripts
    - elisp-formatter/: Emacs Lisp formatting tool
    - shared-programs.nix: shared program configurations
    - window-manager.nix: window management settings
    - git-*.nix: Git-related configurations

- Auxiliary scripts via stow/
  - stow/aux-scripts, stow/nix-scripts, stow/raycast-scripts, etc., are symlinked into the home directory
  - Raycast- and other user-invoked scripts end up in ~/.local/share/bin (see stow/README.md and stow/*/README.md)

Repo-specific practices and conventions
- Use the nb and ns aliases to build and switch the macOS configuration when available.
- Scripts intended for Raycast should live in ~/.local/share/bin; this repo achieves that with stow packages (see stow/README.md).
- Hybrid secret management approach:
  - agenix: SSH keys, certificates, system secrets (encrypted with age)
  - 1Password: User credentials, API tokens (authenticated, enterprise-grade)
  - pass: Backup credential store (offline, GPG-encrypted)
  - Use the unified 'secret' command for all credential operations
  - Traditional scripts still available: check-keys/create-keys/copy-keys/apply

Cross-references
- Root flake: flake.nix (inputs, apps, devShells, darwin configurations)
- macOS helper scripts: apps/aarch64-darwin/
- Module overviews: modules/README.md
- System configuration: system.nix (Darwin configuration at root level)
- Stow-managed scripts and usage: stow/README.md and package READMEs under stow/
- Configuration helper scripts: scripts/ (configure-user.sh, add-host.sh, setup-secrets scripts)
- Overlays: overlays/ (Nix package overlays)

