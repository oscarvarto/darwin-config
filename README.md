# Darwin Configuration

A comprehensive macOS system configuration using Nix-Darwin and Home Manager with flakes support. While designed as a single-user repository, it includes tools to easily adapt the configuration for different users, machines, and environments.

## 🚀 Quick Start

### Initial Setup

1. **Clone the Repository:**
   ```bash
   git clone <your-repo-url> ~/darwin-config
   cd ~/darwin-config
   ```

2. **Configure for Your Environment:**
   ```bash
   # Add your hostname to flake.nix
   nix run .#add-host -- --hostname $(hostname -s) --user $USER
   
   # Or configure for different user/hostname combinations
   nix run .#configure-user -- --user $USER --hostname $(hostname -s)
   ```

3. **Build and Switch:**
   ```bash
   # Using preferred aliases (if available)
   nb   # Build the nix configuration
   ns   # Build and switch to the new configuration
   
   # Or using nix run commands
   nix run .#build-switch
   ```

### Development Workflow

```bash
# Validate configuration
nix flake check

# Format Nix files
nix fmt .

# Enter development shell
nix develop
```

## 🛠️ Available Nix Apps

### Core Build Commands
| Command | Description |
|---------|-------------|
| `nix run .#build` | Build the configuration |
| `nix run .#build-switch` | Build and switch to new configuration |
| `nix run .#apply` | Apply configuration changes |
| `nix run .#rollback` | Rollback to previous generation |

### Configuration Management
| Command | Description |
|---------|-------------|
| `nix run .#add-host` | Add new host configuration to flake.nix |
| `nix run .#configure-user` | Configure for different user/hostname combinations |
| `nix run .#update-doom-config` | Update Doom Emacs configuration with user details |

### Security & Secrets
| Command | Description |
|---------|-------------|
| `nix run .#setup-1password-secrets` | Set up 1Password for secure git credentials |
| `nix run .#setup-pass-secrets` | Set up pass for secure git credentials |
| `nix run .#check-keys` | Check if required SSH keys exist |
| `nix run .#create-keys` | Create SSH keys (id_ed25519, id_ed25519_agenix) |
| `nix run .#copy-keys` | Copy SSH keys from mounted USB to ~/.ssh |

### Enhanced Secret Management
| Command | Description |
|---------|-------------|
| `secret status` | Show status of all credential systems |
| `secret list` | List all available agenix secrets |
| `secret create <name>` | Create new agenix secret |
| `secret edit <name>` | Edit existing agenix secret |
| `secret show <name>` | Display decrypted secret content |
| `secret rekey` | Re-encrypt all agenix secrets with current keys |
| `secret sync-git` | Update git configs from 1Password/pass credentials |
| `secret op-get <item>` | Get 1Password item |
| `secret pass-get <path>` | Get pass entry |
| `backup-secrets` | Backup all secrets, keys, and configurations |
| `setup-secrets-repo` | Clone and setup secrets repository |

### Repository Management
| Command | Description |
|---------|-------------|
| `nix run .#sanitize-repo` | Sanitize repository of sensitive information |

## ✨ Key Features

- **🔄 Multi-User/Multi-Host**: Easily configure for different users and machines
- **⚙️ Dynamic Configuration**: User paths and settings automatically adapt
- **🏢 Work/Personal Profiles**: Conditional configurations for different use cases
- **🔐 Hybrid Secrets Management**: Multi-layered security with agenix, 1Password, and pass
  - **agenix**: SSH keys, certificates, system secrets (encrypted with age)
  - **1Password**: User credentials, API tokens (authenticated, enterprise-grade)
  - **pass**: Backup credential store (offline, GPG-encrypted)
  - **Unified CLI**: Single `secret` command for all credential systems
- **📦 Package Management**: Nix packages + Homebrew integration
- **🐚 Shell Configuration**: Nushell, Zsh with smart aliases and PATH management
- **🔧 Development Tools**: Complete development environment with LSPs, formatters, etc.
- **🔒 Security First**: Automated backups, key rotation, and credential synchronization

## 📁 What's Included

### Core Tools
- **Nix Package Manager** with flakes
- **Home Manager** for user configuration
- **Homebrew** integration for GUI apps
- **Stow** for dotfiles management

### Development Environment
- **Languages**: Rust, Go, Node.js, Python, Java, C++
- **Editors**: Neovim, Helix, Emacs, VS Code
- **Version Control**: Git with smart conditional configs
- **Terminals**: Nushell, Zsh with beautiful prompts

### macOS Integration
- **System Preferences**: Dock, Finder, trackpad settings
- **GUI Applications**: Development tools, productivity apps
- **Fonts**: Programming fonts and icon fonts
- **Services**: LaunchAgent configurations

## 🏗️ Architecture

```
flake.nix              # Main flake with inputs, hostConfigs, and apps
├── system.nix         # System-level macOS configuration
├── apps/              # System-specific executable scripts
│   ├── aarch64-darwin/    # Apple Silicon scripts
│   └── x86_64-darwin/     # Intel Mac scripts
├── modules/           # Modular configuration components
│   ├── home-manager.nix   # User environment & programs
│   ├── packages.nix       # Nix packages
│   ├── casks.nix          # Homebrew casks
│   ├── secrets.nix        # Age-encrypted secrets configuration
│   ├── secure-credentials.nix # 1Password/pass integration
│   ├── enhanced-secrets.nix   # Unified secret management CLI
│   ├── dock/              # macOS Dock configuration
│   ├── nushell/           # Nushell shell configuration
│   ├── elisp-formatter/   # Emacs Lisp formatting tool
│   └── scripts/nu/        # Nushell utility scripts
├── scripts/           # Configuration helper scripts
│   ├── configure-user.sh  # User/hostname configuration
│   ├── add-host.sh        # Add new host to flake
│   └── setup-*-secrets.sh # Secrets management scripts
├── stow/              # GNU Stow packages for dotfiles
│   ├── raycast-scripts/   # Raycast automation scripts
│   ├── nix-scripts/       # Nix-related utilities
│   ├── doom-emacs/        # Doom Emacs configuration
│   └── .../               # Various tool configurations
└── overlays/          # Nix package overlays
```

## 📖 Documentation

- **[Multi-User Setup Guide](MULTI-USER-SETUP.md)** - Comprehensive guide for adapting to different users and machines
- **[Secrets Management Guide](SECRETS-MANAGEMENT.md)** - Secure credential management with 1Password and pass
- **[Scripts Documentation](scripts/)** - Details on the automation tools

## 🔧 Configuration Examples

### Personal Machine
```nix
your-hostname = {
  user = "alice";
  system = "aarch64-darwin";
  hostSettings = {
    enablePersonalConfig = true;
    workProfile = false;
  };
};
```

### Work Machine
```nix
work-laptop = {
  user = "alice";
  system = "aarch64-darwin";
  hostSettings = {
    enablePersonalConfig = false;
    workProfile = true;
  };
};
```

## 🤝 Contributing

This configuration is designed to be a starting point. Feel free to:
- Fork and customize for your needs
- Submit issues for bugs or improvements
- Share your own modifications and enhancements

## 📝 License

This configuration is provided as-is. Feel free to use, modify, and distribute according to your needs.

---

**Getting Started**: Check out the [Multi-User Setup Guide](MULTI-USER-SETUP.md) for detailed instructions on adapting this configuration for your environment.
