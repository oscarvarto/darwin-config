# Important Implementation Notes

### Multi-User Adaptation
- Add new hosts via `nix run .#add-host`
- Host-specific settings in `flake.nix` `hostConfigs`
- Multi-machine profiles affect git configs, directory structures

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
