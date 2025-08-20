# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

- Repository: darwin-config (macOS and NixOS system configuration managed with flakes)
- Primary focus here: macOS aarch64-darwin workflows, plus shared structure used by both macOS and NixOS

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
  - apps: System-specific CLI entrypoints that execute scripts under apps/<system>/ (e.g., build, build-switch, check-keys, create-keys, copy-keys, rollback)
  - darwinConfigurations: Built via mkDarwinConfig(system)
    - Modules include: home-manager.darwinModules.home-manager, nix-homebrew.darwinModules.nix-homebrew, taps (core/cask/bundle/emacs-plus), and system.nix
    - A host named predator is explicitly defined for aarch64-darwin; flake also maps mkDarwinConfig across supported darwin systems
  - nixosConfigurations: Includes disko, home-manager (users.${user} from modules/nixos/home-manager.nix), and hosts/nixos

- Modules layout (summaries from module READMEs)
  - modules/ (formerly darwin-specific, now unified)
    - home-manager.nix: user programs
    - packages.nix: macOS packages
    - casks.nix: Homebrew casks
    - files.nix: immutable non-Nix files
    - dock/: macOS Dock config
    - nushell/: Nushell configuration
    - scripts/: Nushell utility scripts
    - elisp-formatter/: Emacs Lisp formatting tool
  - modules/nixos/
    - default.nix: system-level config
    - home-manager.nix: user programs
    - packages.nix: NixOS packages
    - disk-config.nix: partitions/filesystems
    - files.nix: immutable non-Nix files
    - secrets.nix: agenix-encrypted secrets
  - modules/shared/
    - default.nix: overlays import
    - home-manager.nix: most shared user-level configuration (git, shells, vim/neovim, tmux, etc.)
    - packages.nix: shared packages
    - files.nix: immutable non-Nix files
    - cachix/: cache settings

- Auxiliary scripts via stow/
  - stow/aux-scripts, stow/nix-scripts, stow/raycast-scripts, etc., are symlinked into the home directory
  - Raycast- and other user-invoked scripts end up in ~/.local/share/bin (see stow/README.md and stow/*/README.md)

Repo-specific practices and conventions
- Use the nb and ns aliases to build and switch the macOS configuration when available.
- Scripts intended for Raycast should live in ~/.local/share/bin; this repo achieves that with stow packages (see stow/README.md).
- Secrets are handled with agenix and a separate non-flake Git repo (flake inputs.secrets). Use the check-keys/create-keys/copy-keys/apply scripts to prepare SSH keys and update placeholders.

Cross-references
- Root flake: flake.nix (inputs, apps, devShells, darwin/nixos configurations)
- macOS helper scripts: apps/aarch64-darwin/
- Module overviews: modules/README.md, modules/nixos/README.md, modules/shared/README.md
- System configuration: system.nix (Darwin configuration at root level)
- Stow-managed scripts and usage: stow/README.md and package READMEs under stow/

