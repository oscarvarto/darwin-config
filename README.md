# Darwin Configuration

A comprehensive macOS system configuration using Nix-Darwin and Home Manager with flakes support. While designed as a single-user repository, it includes tools to easily adapt the configuration for different users, machines, and environments.

## 🚀 Installation Guide for macOS

This configuration supports both Apple Silicon (M1/M2/M3) and Intel Macs running macOS Monterey (12.0) or later.

### Prerequisites

Make sure you have:
- macOS Monterey (12.0) or later
- Admin privileges on your Mac
- Internet connection for downloading packages

### 1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

### 2. Install Nix Package Manager

We recommend using the Determinate Systems installer for the best macOS experience:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**After installation, open a new terminal session** to make the `nix` command available in your `$PATH`.

> **⚠️ Important Notes:**
>
> - The installer will ask if you want to install Determinate Nix. Answer **No** as it currently conflicts with `nix-darwin`.
> - If you're on macOS Sequoia, read [Nix Support for macOS Sequoia](https://determinate.systems/posts/nix-support-for-macos-sequoia/) before installing.
>
> **Alternative: Official Nix Installation**
>
> If using the [official Nix installer](https://nixos.org/download) instead, you'll need to enable flakes and nix-command:
>
> Add this line to `/etc/nix/nix.conf`:
> ```
> experimental-features = nix-command flakes
> ```

### 3. Clone and Initialize Repository

```bash
# Clone the repository
git clone <your-repo-url> ~/darwin-config
cd ~/darwin-config

# Make scripts executable
find apps/$(uname -m | sed 's/arm64/aarch64/')-darwin -type f -exec chmod +x {} \;
```

### 4. Configure for Your Environment

```bash
# Configure for your user and hostname
nix run .#configure-user -- --user $USER --hostname $(hostname -s)

# OR add your hostname if it doesn't exist in flake.nix
nix run .#add-host -- --hostname $(hostname -s) --user $USER

# Apply user information to configuration files
nix run .#apply
```

> **📝 Note**: If you're using a git repository, run `git add .` before building to ensure all files are included in the Nix store.

### 5. Review and Customize Packages

Before building, review what will be installed:

**Package Configuration Files:**
- `modules/packages.nix` - Nix packages (CLI tools, development tools)
- `modules/casks.nix` - Homebrew casks (GUI applications)
- `modules/brews.nix` - Homebrew formulas (additional CLI tools)

**Search for packages:**
- [NixOS Package Search](https://search.nixos.org/packages)
- [Homebrew Cask Search](https://formulae.brew.sh/cask/)
- [Homebrew Formula Search](https://formulae.brew.sh/formula/)

### 6. Optional: Setup SSH Keys and Secrets

If you want to use the full secrets management features:

#### Option A: Create New Keys
```bash
nix run .#create-keys
```

> After creating keys, add the public key to your GitHub account:
> ```bash
> cat ~/.ssh/id_ed25519.pub | pbcopy  # Copy to clipboard
> ```

#### Option B: Copy Existing Keys
If you have existing SSH keys on a USB drive:
```bash
nix run .#copy-keys
```

#### Option C: Check Existing Keys
If you already have keys installed:
```bash
nix run .#check-keys
```

### 7. Test Build Configuration

Before switching to the new configuration, test that it builds successfully:

```bash
nix run .#build
```

> **⚠️ Common Issues:**
>
> **File Conflicts**: If you encounter "Unexpected files in /etc, aborting activation":
> ```bash
> # Backup conflicting files (example)
> sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
> sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
> ```
>
> **Sequoia GID Issues**: If you see "Build user group has mismatching GID":
> - You may need to uninstall and reinstall Nix with `--nix-build-group-id 30000`
> - See [macOS Sequoia support documentation](https://determinate.systems/posts/nix-support-for-macos-sequoia/)

### 8. Deploy Configuration

Once the build succeeds, switch to your new configuration:

```bash
# Build and switch to new configuration
nix run .#build-switch

# OR use aliases (after first successful switch)
nb   # Build configuration
ns   # Build and switch
```

### 9. Deploy Stow Packages

After the initial Nix configuration is deployed, set up additional tools and scripts:

```bash
# Deploy all stow-managed scripts and configurations
manage-aux-scripts deploy

# Install development toolchains
manage-cargo-tools install     # Rust tools
manage-nodejs-tools install    # Node.js tools
manage-dotnet-tools install    # .NET tools
```

### 10. Optional: Setup Enhanced Secrets

For full credential management integration:

```bash
# Setup 1Password integration
nix run .#setup-1password-secrets

# OR setup pass as backup credential store
nix run .#setup-pass-secrets

# Check secret management status
secret status
```

## 🔄 Development Workflow

```bash
# Validate configuration
nix flake check

# Format Nix files
nix fmt .

# Enter development shell
nix develop

# Make configuration changes
# ... edit files ...

# Apply changes
nb && ns  # Build and switch with aliases
# OR
nix run .#build-switch
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

### GNU Stow Package Management
| Command | Description |
|---------|-------------|
| `manage-aux-scripts deploy` | Deploy all stow-managed scripts and configurations |
| `manage-aux-scripts remove` | Remove all stow-managed symlinks |
| `stow -t ~ PACKAGE` | Deploy specific stow package (e.g., doom-emacs, raycast-scripts) |
| `stow -D -t ~ PACKAGE` | Remove specific stow package |
| `manage-cargo-tools install` | Install/update Rust/Cargo tools from configuration |
| `manage-nodejs-tools install` | Install/update Node.js tools and toolchain |
| `manage-dotnet-tools install` | Install/update .NET SDK and global tools |

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

## 🗂️ GNU Stow Package Management

This repository uses **GNU Stow** to manage auxiliary scripts, dotfiles, and tools that are difficult to embed directly in Nix configuration. Stow creates symlinks from your home directory to files in the repository, providing version control and easy deployment.

### Available Stow Packages

| Package | Description | Target Location |
|---------|-------------|----------------|
| **aux-scripts** | Utility scripts and tools | `~/.local/share/bin/` |
| **doom-emacs** | Complete Doom Emacs configuration | `~/.doom.d/` |
| **lazyvim** | Neovim LazyVim configuration | `~/.config/nvim/` |
| **raycast-scripts** | Raycast automation scripts | `~/.local/share/bin/` |
| **nix-scripts** | Nix-related utility scripts | `~/.local/share/bin/` |
| **cargo-tools** | Rust/Cargo tools management | `~/.local/share/bin/` |
| **nodejs-tools** | Node.js tools and toolchain management | `~/.local/share/bin/` |
| **dotnet-tools** | .NET SDK and global tools management | `~/.local/share/bin/` |

### Quick Stow Commands

```bash
# Navigate to stow directory
cd ~/darwin-config/stow

# Deploy all packages at once
manage-aux-scripts deploy

# Deploy specific packages
stow -t ~ doom-emacs      # Deploy Doom Emacs config
stow -t ~ raycast-scripts # Deploy Raycast scripts
stow -t ~ aux-scripts     # Deploy utility scripts

# Remove packages
stow -D -t ~ doom-emacs   # Remove Doom Emacs config
manage-aux-scripts remove # Remove all packages
```

### Tool Management Scripts

After deploying the appropriate stow packages, these management commands become available:

```bash
# Development toolchain management
manage-cargo-tools install    # Install Rust tools from cargo-tools.toml
manage-nodejs-tools install   # Install Node.js toolchain from nodejs-tools.toml
manage-dotnet-tools install   # Install .NET SDK from dotnet-tools.toml

# Configuration management
manage-doom-config            # Update Doom Emacs with user settings
```

### When to Use Stow vs. Nix

**Use Stow for:**
- Complex shell scripts that are hard to escape in Nix
- Editor configurations with many files (Doom Emacs, LazyVim)
- Raycast scripts that need specific file locations
- Development tool management scripts

**Use Nix for:**
- System packages and services
- Environment variables and PATH management
- Application configurations that can be templated
- Secrets and credential management

### Adding New Stow Packages

1. Create a new directory in `stow/` with the package name
2. Structure files to mirror your home directory:
   ```
   stow/my-package/
   └── .local/
       └── share/
           └── bin/
               └── my-script
   ```
3. Deploy with `stow -t ~ my-package`
4. Add documentation to the package's README.md

## 🔤 Font Management & Fallback System

This configuration includes an intelligent font fallback system that provides seamless support for both commercial and open-source programming fonts.

### 🎯 Font Hierarchy

The system automatically detects available fonts and uses them in this priority order:

1. **MonoLisa Variable** (commercial) - Premium programming font with extensive ligature support
2. **PragmataPro Liga** (commercial) - Compact, feature-rich programming font
3. **JetBrains Mono** (open source) - High-quality fallback with excellent readability
4. **System fonts** (SF Mono, monospace) - Final fallback

### 🛠️ Font Detection Utility

After deploying stow packages, the `detect-fonts` utility becomes available:

```bash
# Check font availability status
detect-fonts status

# Get recommended font for current system
detect-fonts emacs-font    # Returns: monolisa, pragmatapro, or jetbrains
detect-fonts ghostty-font  # Returns: actual font name for terminal

# Check specific font availability
detect-fonts check "JetBrains Mono"
```

### 📱 Application Integration

#### Emacs/Doom Emacs
- **Font cycling**: Press `F8` to cycle through all available fonts
- **Automatic ligatures**: Each font includes optimized ligature configuration
- **Size optimization**: Fonts use their optimal sizes (MonoLisa: 16pt, PragmataPro: 18pt, JetBrains: 14pt)
- **PragmataPro ligatures**: Custom ligature engine with 200+ programming symbols

#### Ghostty Terminal
- **Base configuration**: Font fallback built into `~/.config/ghostty/config`
- **Runtime switching**: Use `ghostty-config font "Font Name"` to switch fonts
- **Automatic fallback**: Missing fonts don't break the configuration

### 📋 Available Font Commands

| Command | Description |
|---------|-------------|
| `detect-fonts status` | Show availability of all programming fonts |
| `detect-fonts emacs-font` | Get recommended font key for Emacs |
| `detect-fonts ghostty-font` | Get recommended font name for terminals |
| `ghostty-config font "Font Name"` | Switch terminal font (with restart) |
| `ghostty-config list` | Show all available font options |

### 🎨 Font Features

**MonoLisa Variable:**
- Variable font technology
- Extensive ligature set
- Script variants
- Optimal at 16pt

**PragmataPro Liga:**
- Ultra-compact design
- Custom ligature engine
- Mathematical symbols
- Optimal at 18pt

**JetBrains Mono (Fallback):**
- Open source alternative
- Good ligature support
- Excellent readability
- Optimal at 14pt
- Available via Nix packages

### 🔧 How It Works

1. **Detection**: System scans available fonts using `fc-list`
2. **Fallback Chain**: Applications automatically use the best available font
3. **Configuration**: Each app includes font-specific optimizations
4. **Runtime Switching**: Tools allow manual font switching when desired

### 💡 For New Installations

If you're setting up on a system without commercial fonts:

1. The system automatically detects JetBrains Mono is available
2. Emacs, Ghostty, and other apps default to JetBrains Mono
3. All ligatures and features work seamlessly
4. You can later add commercial fonts and switch to them using `F8` in Emacs

### 🎯 Benefits

- **Zero Configuration**: Works out of the box on any system
- **Graceful Degradation**: Missing fonts don't break anything
- **Consistent Experience**: Same ligatures and features across fonts
- **Easy Migration**: Add commercial fonts later without reconfiguration
- **Developer Friendly**: Optimized for programming with proper ligature support

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
- **Fonts**: Programming fonts with intelligent fallback system
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
