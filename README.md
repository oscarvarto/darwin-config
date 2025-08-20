# Darwin Configuration with Multi-User Support

A comprehensive macOS configuration using Nix-Darwin and Home Manager, designed to be easily portable across different users and machines.

## 🚀 Quick Start

### For Your First Machine

1. **Clone and Setup:**
   ```bash
   git clone https://github.com/your-username/darwin-config.git ~/darwin-config
   cd ~/darwin-config
   ```

2. **Add Your Host:**
   ```bash
   # Automatically add your machine configuration
   nix run .#add-host -- --hostname $(hostname -s) --user $USER --personal-config
   ```

3. **Build and Switch:**
   ```bash
   nix run .#build-switch
   ```

### For Additional Machines

```bash
# Configure for different user/hostname combinations
nix run .#configure-user -- --user alice --hostname work-laptop --work-profile
```

## 🛠️ Available Nix Apps

| Command | Description |
|---------|-------------|
| `nix run .#build` | Build the configuration |
| `nix run .#build-switch` | Build and switch to new configuration |
| `nix run .#add-host` | Add new host configuration to flake.nix |
| `nix run .#configure-user` | Configure for different user/hostname |
| `nix run .#setup-1password-secrets` | Set up 1Password for secure credentials |
| `nix run .#setup-pass-secrets` | Set up pass for secure credentials |
| `nix run .#apply` | Apply configuration changes |
| `nix run .#rollback` | Rollback to previous generation |

## ✨ Key Features

- **🔄 Multi-User/Multi-Host**: Easily configure for different users and machines
- **⚙️ Dynamic Configuration**: User paths and settings automatically adapt
- **🏢 Work/Personal Profiles**: Conditional configurations for different use cases
- **🔐 Secrets Management**: Age-encrypted secrets with dynamic user paths
- **📦 Package Management**: Nix packages + Homebrew integration
- **🐚 Shell Configuration**: Nushell, Zsh with smart aliases and PATH management
- **🔧 Development Tools**: Complete development environment with LSPs, formatters, etc.

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
flake.nix              # Main configuration with hostConfigs
├── system.nix         # System-level configuration
├── modules/           # Modular configuration
│   ├── home-manager.nix   # User environment
│   ├── packages.nix       # Package lists
│   ├── secrets.nix        # Age-encrypted secrets
│   └── ...
├── scripts/           # Helper scripts
│   ├── configure-user.sh  # User configuration tool
│   └── add-host.sh        # Host addition tool
└── stow/             # User scripts and dotfiles
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
