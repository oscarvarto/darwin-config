# Darwin Configuration

A comprehensive macOS system configuration using Nix-Darwin and Home Manager with flakes support. While designed as a single-user repository, it includes tools to easily adapt the configuration for different users, machines, and environments.

## 📋 Table of Contents

### 🚀 Getting Started
- [🚀 Installation Guide for macOS](#-installation-guide-for-macos)
  - [Prerequisites](#prerequisites)
  - [1. Install Xcode Command Line Tools](#1-install-xcode-command-line-tools)
  - [2. Install Nix Package Manager](#2-install-nix-package-manager)
  - [3. Clone and Initialize Repository](#3-clone-and-initialize-repository)
  - [4. Configure for Your Environment](#4-configure-for-your-environment)
  - [5. Review and Customize Packages](#5-review-and-customize-packages)
  - [6. Optional: Setup SSH Keys and Secrets](#6-optional-setup-ssh-keys-and-secrets)
  - [7. Test Build Configuration](#7-test-build-configuration)
  - [8. Deploy Configuration](#8-deploy-configuration)
  - [9. Deploy Stow Packages](#9-deploy-stow-packages)
  - [10. Optional: Setup Enhanced Secrets](#10-optional-setup-enhanced-secrets)

### 🔧 Development & Maintenance
- [🔄 Development Workflow](#-development-workflow)
  - [📦 Updating Software Versions](#-updating-software-versions)
  - [🧹 System Maintenance](#-system-maintenance)
  - [📌 Package Pinning System](#-package-pinning-system)
- [🛠️ Available Nix Apps](#%EF%B8%8F-available-nix-apps)

### ✨ Key Features & Systems
- [✨ Key Features](#-key-features)
- [🗂️ GNU Stow Package Management](#%EF%B8%8F-gnu-stow-package-management)
- [🔤 Font Management & Fallback System](#-font-management--fallback-system)
- [✏️ Editor Configurations](#%EF%B8%8F-editor-configurations)
  - [🚀 Doom Emacs Configuration](#-doom-emacs-configuration)
  - [🌟 Neovim (LazyVim) Configuration](#-neovim-lazyvim-configuration)
  - [🛠️ Editor Management with Stow](#%EF%B8%8F-editor-management-with-stow)
- [🧠 IntelliJ IDEA Development Utilities](#-intellij-idea-development-utilities)
- [🐚 Choosing Your Default Shell](#-choosing-your-default-shell)

### 📚 Architecture & Documentation
- [📁 What's Included](#-whats-included)
- [🏗️ Architecture](#%EF%B8%8F-architecture)
- [📖 Documentation](#-documentation)
- [🔧 Configuration Examples](#-configuration-examples)

### 🤝 Contributing & License
- [🤝 Contributing](#-contributing)
- [📝 License](#-license)

---

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
manage-stow-packages deploy

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

### 📦 Updating Software Versions

To get the latest software versions and package updates:

```bash
# Update flake lock file to latest versions
nix flake update

# Update specific input (optional)
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# After updating, rebuild and switch
nb && ns
```

**What `nix flake update` does:**
- Updates `flake.lock` with latest versions of nixpkgs, home-manager, and other inputs
- Gets security updates and new package versions
- May introduce breaking changes, so test after updating
- Equivalent to updating your "package manager" in other systems

### 🧹 System Maintenance

For regular system cleanup and maintenance:

```bash
# Check current disk usage and generation status
smart-gc status

# Preview what would be cleaned (no changes made)
smart-gc dry-run

# Smart cleanup (keeps last 3 generations)
smart-gc clean

# Conservative cleanup (keeps last 7 generations)
smart-gc conservative

# Aggressive cleanup with store optimization
smart-gc aggressive --force --optimize
```

**Smart GC features:**
- **Preserves recent generations** to avoid breaking your system
- **Pins essential packages** to prevent removal
- **Store optimization** to hard-link identical files and save space
- **Dry-run mode** to preview changes before applying
- **Multiple cleanup modes** for different maintenance needs

**Recommended maintenance schedule:**
- **After major changes**: Run `smart-gc dry-run` to check what can be cleaned
- **Weekly**: `smart-gc clean` to keep 3 recent generations
- **Monthly**: `smart-gc conservative --optimize` for deeper cleanup with optimization
- **Before major updates**: `smart-gc status` to check disk usage

### 📌 Package Pinning System

The `smart-gc` utility includes a package pinning system to prevent accidental removal of essential packages during garbage collection. This system creates GC roots that keep specific packages and their dependencies in the Nix store.

#### Understanding Package Pinning

**What pinning does:**
- Creates GC roots for specified packages, preventing garbage collection
- Ensures critical system tools remain available after cleanup
- Protects the current system configuration from removal

**What pinning does NOT do:**
- ❌ **Does NOT prevent package updates** - pinned packages can still be updated normally
- ❌ Does not pin to specific versions - only prevents garbage collection
- ❌ Does not interfere with `nix flake update` or rebuilding the system

#### Using the Pinning System

```bash
# Pin essential packages to prevent removal
smart-gc pin

# Check current pinning status
smart-gc status  # Shows GC roots including pinned packages

# Clean while respecting pinned packages  
smart-gc clean   # Pinned packages and dependencies are preserved
```

#### Customizing Essential Packages

The essential packages list is defined in `smart-gc.nu`. Currently, most packages are commented out by default to avoid over-pinning:

```nushell
# Edit the essential_packages list in smart-gc.nu
let essential_packages = [
  # "nixpkgs#git",           # Uncomment to pin git
  # "nixpkgs#curl",          # Uncomment to pin curl 
  # "nixpkgs#starship",      # Uncomment to pin starship
  # "nixpkgs#helix",         # Uncomment to pin helix editor
  # Add your own essential packages here
]
```

**To add your own essential packages:**

1. **Edit the script:**
   ```bash
   # Navigate to the script location
   cd ~/darwin-config/stow/nix-scripts/.local/share/bin/
   
   # Edit smart-gc.nu to uncomment or add packages
   nvim smart-gc.nu
   ```

2. **Add packages to the list:**
   ```nushell
   let essential_packages = [
     "nixpkgs#git",              # Version control
     "nixpkgs#curl",             # HTTP client
     "nixpkgs#your-package",     # Your essential package
   ]
   ```

3. **Apply the pinning:**
   ```bash
   smart-gc pin
   ```

#### Pinning vs. Updates - Key Points

**✅ Pinning is update-friendly:**
- Pinned packages update normally with `nix flake update` and system rebuilds
- Pinning only prevents garbage collection, not version changes
- New versions of pinned packages replace old versions in the store
- Only the cleanup process respects the pinning

**Example workflow:**
```bash
# 1. Pin essential packages
smart-gc pin

# 2. Update your system normally
nix flake update
nb && ns  # Build and switch

# 3. Clean up old generations (pinned packages remain)
smart-gc clean

# Result: You have updated packages + protected against over-aggressive cleanup
```

#### When to Use Pinning

**✅ Good candidates for pinning:**
- Core development tools (git, curl, text editors)
- System utilities you always need
- Packages that are expensive to rebuild
- Tools required for system recovery

**❌ Avoid pinning:**
- Packages that update frequently
- Large packages you rarely use
- Packages already managed by your system configuration
- Development tools for specific projects

#### Managing Pinned Packages

```bash
# View what's currently pinned
smart-gc status
ls -la /nix/var/nix/gcroots/  # Direct inspection of GC roots

# Remove pinning (if needed)
# Currently requires manual GC root removal:
sudo rm /nix/var/nix/gcroots/current-system  # Remove system pinning
# Remove package-specific roots as needed

# Re-pin after changes
smart-gc pin
```

#### Technical Details

The pinning system works by:
1. **System Configuration**: Creates a GC root for the current system derivation
2. **Essential Packages**: Uses `nix build --no-link --print-out-paths` to realize packages and create implicit GC roots
3. **GC Root Storage**: Stores roots in `/nix/var/nix/gcroots/` where the garbage collector respects them

This approach ensures that while garbage collection won't remove pinned packages, the normal update and rebuild processes work exactly as expected.

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

### Development Utilities
| Command | Description |
|---------|-------------|
| `cleanup-intellij [project]` | Clean IntelliJ IDEA caches and fix broken state |

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
- **🐚 Advanced Shell Configuration**: Choose between Nushell, Fish, and Zsh with:
  - **Consistent Experience**: Same aliases, PATH, and tools across all shells
  - **Smart Switching**: Easy shell changes via simple configuration updates
  - **Modern Features**: Starship prompts, Zoxide navigation, Atuin history
  - **Seamless Integration**: Terminal, editor, and development tool compatibility
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

## ✏️ Editor Configurations

This repository includes comprehensive configurations for both Doom Emacs and Neovim (LazyVim), managed through the stow system for easy deployment and version control.

### 🚀 Doom Emacs Configuration

A complete, modular Doom Emacs configuration with advanced features, language support, and development tools.

#### Quick Setup

```bash
# 1. Install Doom Emacs (if not already installed)
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install

# 2. Deploy configuration via stow
manage-aux-scripts deploy doom-emacs
# OR deploy all packages: manage-aux-scripts deploy

# 3. Sync Doom with new configuration
doom sync
```

#### Configuration Structure

```
~/.doom.d/  (symlinked from ~/darwin-config/stow/doom-emacs/.doom.d/)
├── init.el          # Doom modules configuration
├── packages.el      # Package declarations and configuration  
├── config.el        # Main configuration loader
├── custom.el        # Emacs custom variables
├── config/          # Modular configuration files
│   ├── ai/          # AI tools (Tabnine, Copilot, etc.)
│   ├── core/        # Core Emacs functionality
│   ├── jvm/         # JVM languages (Java, Scala)
│   ├── languages/   # Programming language configurations
│   ├── lsp/         # Language Server Protocol setup
│   ├── misc/        # Miscellaneous configurations
│   ├── ui/          # User interface customizations
│   └── writing/     # Writing and documentation tools
├── snippets/        # YASnippet templates
└── docs/           # Configuration documentation
```

#### Key Features

- **🧠 AI Integration**: Tabnine, GitHub Copilot support
- **🛠️ LSP Support**: Language servers for 15+ programming languages
- **🎨 Advanced UI**: Custom themes, fonts, ligatures, modeline
- **📁 Project Management**: Projectile, Treemacs, smart project detection
- **🔍 Search & Navigation**: Vertico, Consult, advanced search capabilities
- **📝 Writing Tools**: Org-mode, Markdown, LaTeX, presentations
- **🚀 Performance**: Lazy loading, optimized startup
- **🔧 Modular Design**: Easy to customize and extend

#### Available Commands & Aliases

| Command | Description |
|---------|-------------|
| `e [files...]` | Open files in GUI Emacs (with daemon) |
| `et` | Start Emacs in background |
| `edd` | Open current directory in Emacs |
| `manage-doom-config status` | Check configuration deployment status |
| `manage-doom-config validate` | Validate all elisp files for syntax |
| `manage-doom-config sync` | Validate config and run `doom sync` |
| `manage-doom-config edit` | Open configuration in Emacs |
| `manage-doom-config backup` | Create timestamped backup |
| `doom sync` | Sync Doom with configuration changes |
| `doom upgrade` | Update Doom Emacs itself |
| `doom doctor` | Diagnose configuration issues |

#### Font Integration

- **Smart Font Detection**: Automatically uses best available programming font
- **Font Cycling**: Press `F8` to cycle between MonoLisa → PragmataPro → JetBrains Mono
- **Ligature Support**: Optimized ligatures for each font
- **Size Optimization**: Each font uses its optimal size settings

#### Configuration Management

```bash
# Edit configuration (preserves version control)
cd ~/darwin-config/stow/doom-emacs/.doom.d/
# Make changes to files here

# Validate changes before committing
manage-doom-config validate

# Sync changes to Doom
manage-doom-config sync

# Commit to version control
git add . && git commit -m "Update Doom config"
```

#### Language Support

**Supported Languages:**
- **Systems**: Rust, Go, C/C++, Zig
- **JVM**: Java, Scala, Clojure, Kotlin
- **Web**: TypeScript, JavaScript, HTML, CSS
- **Data**: Python, R, SQL, JSON, YAML
- **Markup**: Markdown, LaTeX, Org-mode
- **Config**: Nix, TOML, INI, Dockerfile
- **And many more...**

#### Troubleshooting

```bash
# Check configuration status
manage-doom-config status

# Validate elisp syntax
manage-doom-config validate

# Diagnose issues
doom doctor

# Re-deploy configuration
manage-aux-scripts remove doom-emacs
manage-aux-scripts deploy doom-emacs
doom sync
```

### 🌟 Neovim (LazyVim) Configuration

A modern Neovim configuration based on LazyVim with sensible defaults and extensive plugin ecosystem.

#### Quick Setup

```bash
# 1. Neovim is already installed via Nix (see modules/packages.nix)

# 2. Deploy LazyVim configuration
cd ~/darwin-config/stow
stow lazyvim
# OR: manage-aux-scripts deploy lazyvim

# 3. Start Neovim (plugins auto-install on first run)
nvim
```

#### Configuration Structure

```
~/.config/nvim/  (symlinked from ~/darwin-config/stow/lazyvim/.config/nvim/)
├── init.lua         # Main configuration entry point
├── lazy-lock.json   # Plugin version lockfile
├── lazyvim.json     # LazyVim configuration
└── lua/
    ├── config/      # Core configuration
    │   ├── autocmds.lua    # Auto-commands
    │   ├── keymaps.lua     # Key bindings
    │   ├── lazy.lua        # Plugin manager setup
    │   └── options.lua     # Neovim options
    └── plugins/     # Plugin configurations
        ├── nixd.lua        # Nix language support
        ├── python.lua      # Python development
        └── example.lua     # Plugin examples
```

#### Key Features

- **📦 Plugin Management**: Lazy.nvim with automatic plugin installation
- **🛠️ LSP Integration**: Built-in language server support
- **🔍 Fuzzy Finding**: Telescope for files, buffers, grep
- **📁 File Explorer**: Neo-tree for project navigation
- **🎨 Modern UI**: Beautiful statusline, bufferline, themes
- **⚡ Performance**: Lazy loading, fast startup
- **🔧 Extensible**: Easy to add custom plugins and configurations

#### Available Commands

| Command | Description |
|---------|-------------|
| `nvim` | Start Neovim with LazyVim configuration |
| `nvim +Lazy` | Open plugin manager |
| `nvim +Mason` | Open LSP installer |
| `nvim +checkhealth` | Check configuration health |

#### Basic Usage

**Key Bindings (LazyVim defaults):**
- `<leader>` = `<Space>`
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>e` - Toggle file explorer
- `<leader>gg` - Open lazygit
- `<leader>l` - LSP commands

#### Configuration Management

```bash
# Edit configuration
cd ~/darwin-config/stow/lazyvim/.config/nvim/
# Make changes to Lua files

# Test configuration
nvim +checkhealth

# Commit changes
git add . && git commit -m "Update LazyVim config"
```

### 🛠️ Editor Management with Stow

Both editor configurations use the stow system for deployment and management.

#### Deploying Editor Configurations

```bash
# Deploy both editors
manage-aux-scripts deploy

# Deploy specific editor
stow -t ~ doom-emacs    # Deploy Doom Emacs config
stow -t ~ lazyvim       # Deploy LazyVim config

# Check deployment status
manage-aux-scripts status
```

#### Removing Editor Configurations

```bash
# Remove specific editor config (preserves files)
stow -D -t ~ doom-emacs
stow -D -t ~ lazyvim

# Remove all stow packages
manage-aux-scripts remove
```

#### Benefits of Stow Management

- **Version Control**: Full history of configuration changes
- **Portability**: Easy to deploy on new systems
- **Safety**: Symlinks preserve original structure
- **Modularity**: Independent editor configurations
- **Backup**: Configurations are part of darwin-config repository

#### Creating Custom Editor Configurations

1. **Create stow package structure:**
   ```bash
   mkdir -p ~/darwin-config/stow/my-editor/.config/my-editor
   # Add configuration files
   ```

2. **Deploy with stow:**
   ```bash
   cd ~/darwin-config/stow
   stow -t ~ my-editor
   ```

3. **Add to management system:**
   - Update `manage-aux-scripts` to include new package
   - Add documentation to package README.md

### 🎯 Editor Recommendations

**Choose Doom Emacs if you:**
- Want extensive customization capabilities
- Need advanced org-mode and writing features
- Prefer elisp for configuration
- Use Emacs ecosystem tools (mu4e, magit, etc.)

**Choose LazyVim/Neovim if you:**
- Prefer faster startup times
- Want modern Lua-based configuration
- Need excellent terminal integration
- Prefer minimal, focused editing experience

**Use Both:**
- Both configurations can coexist
- Doom Emacs for heavy development and writing
- LazyVim for quick edits and terminal work

## 🧠 IntelliJ IDEA Development Utilities

### 🛠️ IntelliJ Cache Cleanup Tool

The `cleanup-intellij` script is a powerful utility for fixing broken IntelliJ IDEA states that can interfere with development. IntelliJ often accumulates corrupt caches, project files, and configuration states that cause issues like:

- Folder structure not being recognized properly
- IDE freezing or becoming unresponsive
- Projects not loading correctly
- Build system integration problems
- Corrupted indexing and caching

#### Quick Usage

```bash
# Clean all IntelliJ caches (most common)
cleanup-intellij

# Clean specific project + all caches
cleanup-intellij ~/my-project

# Clean only project files
cleanup-intellij -p ~/my-project

# Clean only system caches
cleanup-intellij -s

# Nuclear option - clean EVERYTHING system-wide
cleanup-intellij -g
```

#### Available Options

| Option | Description |
|--------|-------------|
| `cleanup-intellij` | Clean all IntelliJ system caches |
| `cleanup-intellij <project>` | Clean all caches + specific project files |
| `cleanup-intellij -p <project>` | Clean only project-specific files (.idea, .iml, etc.) |
| `cleanup-intellij -s` | Clean only system caches and application data |
| `cleanup-intellij -g` | **Aggressive**: Clean ALL project files system-wide |
| `cleanup-intellij -h` | Show help and usage examples |

#### What Gets Cleaned

**System Caches (`-s` or default):**
- `~/Library/Caches/JetBrains/IntelliJIdea*` - IDE caches
- `~/Library/Logs/JetBrains/IntelliJIdea*` - IDE logs
- `~/Library/Application Support/JetBrains/IntelliJIdea*/workspace` - Workspace data
- `~/Library/Application Support/JetBrains/IntelliJIdea*/system` - System data
- `~/Library/Application Support/JetBrains/IntelliJIdea*/scratches_and_consoles` - Scratches
- Recent projects configuration

**Project-Specific Files (`-p`):**
- `.idea/` directory (project configuration)
- `*.iml` files (module files)
- `*.ipr` files (legacy project files)
- `*.iws` files (workspace files)
- Project references from trusted-paths.xml

**Aggressive Cleanup (`-g`):**
- **ALL** `.idea` directories system-wide (excluding system directories)
- **ALL** `.iml`, `.ipr`, `.iws` files system-wide
- All system caches and application data
- ⚠️ **Warning**: This will reset ALL IntelliJ projects!

#### Common Use Cases

**Project Won't Load Correctly:**
```bash
# Clean specific project + caches
cleanup-intellij ~/problematic-project
```

**IntelliJ Feels Slow/Corrupted:**
```bash
# Clean all system caches
cleanup-intellij -s
```

**Fresh Start for Specific Project:**
```bash
# Clean only project files (preserves other projects)
cleanup-intellij -p ~/my-project
```

**Nuclear Reset (Use with Caution):**
```bash
# Clean everything - like fresh IntelliJ install
cleanup-intellij -g
# You'll be prompted for confirmation
```

#### Safety Features

- **Colored output** with clear status messages
- **Confirmation prompt** for aggressive mode
- **Safe removal** - only deletes files if they exist
- **Path validation** - ensures project paths are valid
- **Exclusions** - skips system directories, node_modules, .Trash

#### When to Use This Tool

✅ **Use when experiencing:**
- Project import/loading failures
- Incorrect folder structure recognition
- IntelliJ freezing or crashes
- Build system not working properly
- Indexing problems
- "Cannot resolve symbol" errors that won't go away

⚠️ **Be careful with:**
- `-g` (aggressive) mode - resets ALL projects
- Projects with custom IntelliJ configurations you want to keep
- Shared projects where team members rely on specific IDE settings

#### Post-Cleanup Steps

 After running the cleanup:

1. **Restart IntelliJ IDEA** completely
2. **Re-import your project** if using aggressive cleanup
3. **Wait for indexing** to complete
4. **Reconfigure** any custom project settings if needed

#### Integration with Development Workflow

```bash
# After pulling major changes
git pull origin main
cleanup-intellij ~/my-project  # Clean project state
# Restart IntelliJ

# Before switching branches with major structural changes
cleanup-intellij -p ~/my-project
git checkout feature-branch
# Restart IntelliJ

# Monthly maintenance
cleanup-intellij -s  # Clean system caches
```

This tool is particularly useful in JVM development environments where IntelliJ's complex project models can become corrupted, especially when working with large codebases, multi-module projects, or frequently switching between branches with different project structures.

## 🐚 Choosing Your Default Shell

This configuration supports three fully-configured shells: **Nushell**, **Fish**, and **Zsh**. Each shell is intelligently configured with consistent features, aliases, and PATH management. You can choose your preferred shell and switch between them seamlessly.

### 🎯 Available Shells

| Shell | Description | Best For |
|-------|-------------|----------|
| **Nushell** | Modern shell with structured data | Data manipulation, pipelines, modern workflows |
| **Fish** | User-friendly with great defaults | Interactive use, beginners, excellent autocompletion |
| **Zsh** | Traditional, highly configurable | Power users, legacy compatibility, extensive plugins |

### 🔧 Setting Your Default Shell

#### For New Installations

When adding a new host to your configuration, specify the `defaultShell` option:

```bash
# Add new host with shell preference
nix run .#add-host -- --hostname $(hostname -s) --user $USER
```

Then edit `flake.nix` to set your shell preference:

```nix
hostConfigs = {
  your-hostname = {
    user = "youruser";
    system = "aarch64-darwin";
    defaultShell = "nushell";  # Options: "nushell", "fish", "zsh"
    hostSettings = {
      enablePersonalConfig = true;
      workProfile = false;
    };
  };
};
```

#### For Existing Configurations

1. **Edit your host configuration in `flake.nix`:**
   ```nix
   predator = {
     user = "oscarvarto";
     system = "aarch64-darwin";
     defaultShell = "fish";  # Change to your preferred shell
     hostSettings = {
       # ... existing settings
     };
   };
   ```

2. **Rebuild your system:**
   ```bash
   nb && ns  # Build and switch
   ```

3. **Update Emacs configuration (optional):**
   ```bash
   nix run .#update-doom-config
   ```

### 🌟 Shell Features

All shells include consistent features configured automatically:

#### Shared Features
- **Starship Prompt**: Modern, fast prompt with git integration
- **Zoxide**: Smart directory jumping with `z` command
- **Atuin**: Improved history with search and sync
- **Yazi**: File manager integration
- **Consistent Aliases**: Same shortcuts across all shells
- **PATH Management**: Unified PATH configuration
- **Development Tools**: Same tools available in all shells

#### Shell-Specific Strengths

**Nushell Features:**
```bash
# Structured data processing
ls | where size > 1MB | sort-by modified

# Built-in data formats
open package.json | get dependencies

# Powerful pipelines
ps | where cpu > 50 | select name cpu
```

**Fish Features:**
```bash
# Excellent autocompletion
cd /usr/loc[TAB]  # Completes to /usr/local/

# Visual command history
# Use up arrow for intelligent history search

# Syntax highlighting in real-time
```

**Zsh Features:**
```bash
# Advanced completion system
# Glob patterns and extended matching

# Plugin ecosystem compatibility
# Customizable prompt systems
```

### 📋 Available Shell Commands

#### Common Aliases (All Shells)

| Alias | Command | Description |
|-------|---------|-------------|
| `nb` | `nix run .#build` | Build darwin configuration |
| `ns` | `nix run .#build-switch` | Build and switch configuration |
| `gp` | `git fetch --all -p; git pull; git submodule update --recursive` | Git pull with submodules |
| `search` | `rg -p --glob '!node_modules/*'` | Ripgrep search excluding node_modules |
| `diff` | `difft` | Better diff tool |
| `edd` | `emacs --daemon=doom` | Start Emacs daemon |
| `ds` | `doom sync --aot --gc` | Doom sync with optimization |

#### Shell Configuration Shortcuts

| Command | Shell | Description |
|---------|-------|-------------|
| `nnc` | All | Edit Nushell config.nu |
| `nne` | All | Edit Nushell env.nu |
| `ffc` | All | Edit Fish config (in home-manager.nix) |
| `tg` | All | Edit terminal config |

### 🔄 Switching Between Shells

#### Quick Shell Testing

```bash
# Try different shells temporarily
fish    # Start fish session
nu      # Start nushell session
zsh     # Start zsh session
exit    # Return to default shell
```

#### Changing Default Shell

1. **Update flake.nix:**
   ```nix
   defaultShell = "fish";  # Change to desired shell
   ```

2. **Rebuild system:**
   ```bash
   nb && ns
   ```

3. **Verify change:**
   ```bash
   echo $SHELL
   # Should show new shell path
   ```

### 🛠️ Advanced Shell Configuration

#### Customizing Shell Behavior

Each shell's configuration can be customized in specific files:

**Nushell**: `modules/nushell/config.nu` and `modules/nushell/env.nu`
**Fish**: `modules/home-manager.nix` (fish section)
**Zsh**: `modules/shell-config.nix` and `modules/zsh-darwin.nix`

#### Adding Custom Aliases

Edit the appropriate configuration file for your shell:

**For Nushell** (`modules/nushell/config.nu`):
```nushell
# Add custom aliases
alias myalias = "your-command"
```

**For Fish** (`modules/home-manager.nix`):
```nix
shellAbbrs = {
  myalias = "your-command";
};
```

**For Zsh** (`modules/shell-config.nix`):
```nix
initContent = lib.mkAfter ''
  alias myalias="your-command"
'';
```

### 🎯 Shell Recommendations

**Choose Nushell if you:**
- Work with structured data (JSON, CSV, XML)
- Like modern, consistent command syntax
- Want powerful data manipulation pipelines
- Prefer type safety and structured output

**Choose Fish if you:**
- Want excellent out-of-the-box experience
- Prefer intuitive, user-friendly interfaces
- Value great autocompletion and history
- Are new to advanced shell features

**Choose Zsh if you:**
- Need maximum compatibility with bash scripts
- Want extensive plugin ecosystem (oh-my-zsh, etc.)
- Prefer traditional Unix shell behavior
- Have existing zsh configurations to port

### ⚡ PATH and Environment Management

All shells use the centralized PATH configuration from `modules/path-config.nix`. This ensures:

- **Consistent PATH**: Same paths across all shells
- **Priority Control**: Your tools take precedence
- **Tool Integration**: Automatic integration with development tools
- **Override Capability**: Your configuration overrides mise, homebrew, etc.

See [PATH Management Documentation](modules/PATH-MANAGEMENT.md) for detailed PATH customization.

### 🔍 Troubleshooting Shell Issues

#### Shell Not Changing
```bash
# Check current shell
echo $SHELL

# Verify configuration
grep -A 5 "$(hostname -s)" flake.nix | grep defaultShell

# Force rebuild
nb && ns
```

#### Missing Features
```bash
# Check if shell programs are enabled
nix run .#build --show-trace

# Verify stow deployment
manage-stow-packages deploy
```

#### Configuration Not Loading
```bash
# Check configuration files exist
ls -la ~/.config/nushell/
ls -la ~/.config/fish/

# Test configuration syntax
# For nushell:
nu --config modules/nushell/config.nu --commands "exit"
```

### 💡 Shell Integration Tips

- **Emacs Integration**: The default shell setting automatically configures vterm and shell-mode
- **Terminal Integration**: All shells work seamlessly with Ghostty, Warp, and other terminals
- **Script Compatibility**: Shell scripts in this repo use bash for maximum compatibility
- **Interactive vs Script**: Your default shell affects interactive sessions, not system scripts

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

### Personal Machine with Nushell
```nix
your-hostname = {
  user = "alice";
  system = "aarch64-darwin";
  defaultShell = "nushell";  # Modern shell for data processing
  hostSettings = {
    enablePersonalConfig = true;
    workProfile = false;
  };
};
```

### Work Machine with Fish
```nix
work-laptop = {
  user = "alice";
  system = "aarch64-darwin";
  defaultShell = "fish";     # User-friendly shell for work
  hostSettings = {
    enablePersonalConfig = false;
    workProfile = true;
  };
};
```

### Traditional Setup with Zsh
```nix
legacy-system = {
  user = "bob";
  system = "x86_64-darwin";
  defaultShell = "zsh";      # Traditional shell with extensive plugins
  hostSettings = {
    enablePersonalConfig = true;
    workProfile = false;
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
