# Code Architecture

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
├── assets/icons/             # Liquid Glass icon pack for Emacs.app
├── terminal-support.nix      # Ghostty terminfo support (NEW)
├── biometric-auth.nix        # macOS biometric authentication (NEW)
├── starship.toml             # Starship prompt with Catppuccin theme
└── [various other modules]
```

### Multi-User/Multi-Host Design
- Host configurations defined in `flake.nix` `hostConfigs` section
- Each host specifies: user, system architecture, defaultShell, hostSettings
- Supports multi-machine profiles with conditional configuration
- Shell choice per host: "nushell" or "zsh"

### Configuration Layer Structure
1. **System Layer** (`system.nix`) - macOS system settings, services
2. **Package Layer** (`modules/packages.nix`) - Nix packages
3. **Application Layer** (`modules/casks.nix`, `brews.nix`) - GUI apps via Homebrew  
4. **User Layer** (`modules/home-manager.nix`) - User environment, dotfiles
5. **Stow Layer** (`stow/`) - Complex configurations (editors, scripts)
