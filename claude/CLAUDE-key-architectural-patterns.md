# Key Architectural Patterns

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
- Consistent Starship prompts, Zoxide navigation
- Note: Fish shell binary is installed only as a completion engine for Nushell
