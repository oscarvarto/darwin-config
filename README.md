# Darwin Configuration

A comprehensive macOS system configuration using Nix-Darwin and Home Manager with flakes support. While designed
as a single-user repository, it includes tools to easily adapt the configuration for different users, machines, and
environments.

> **Note:** This is a **pragmatic, hybrid configuration** that combines the best of **Nix**, **GNU Stow**, and
> **Homebrew**.
>
> Rather than a “pure” Nix setup, this approach pragmatically uses each tool for what it does best:
> - Nix for reproducible system configuration and packages,
> - GNU Stow for managing selected dotfiles and editor configs,
> - and Homebrew for applications and tools that are easier to handle outside Nix.

## Table of Contents

### Getting Started

- [Installation Guide for macOS](#installation-guide-for-macos)
  - [Prerequisites](#prerequisites)
  - [1. Install Xcode Command Line Tools](#1-install-xcode-command-line-tools)
  - [2. Install Nix Package Manager](#2-install-nix-package-manager)
  - [3. Clone and Initialize Repository](#3-clone-and-initialize-repository)
  - [4. Configure for Your Environment](#4-configure-for-your-environment)
  - [5. Optional: Tune Nix Performance](#5-optional-tune-nix-performance-for-your-hardware)
  - [6. Review and Customize Packages](#6-review-and-customize-packages)
  - [7. Optional: Setup SSH Keys and Secrets](#7-optional-setup-ssh-keys-and-secrets)
  - [8. Test Build Configuration](#8-test-build-configuration)
  - [9. Deploy Configuration](#9-deploy-configuration)
  - [10. Deploy Stow Packages](#10-deploy-stow-packages)
  - [11. Optional: Setup Enhanced Secrets](#11-optional-setup-enhanced-secrets)

### Development & Maintenance

- [Development Workflow](#development-workflow)
  - [Updating Software Versions](#updating-software-versions)
  - [System Maintenance](#system-maintenance)
  - [Package Pinning System](#package-pinning-system)
- [Available Nix Apps](#available-nix-apps)

### Key Features & Systems

- [Key Features](#key-features)
- [Ghostty Terminal](#ghostty-terminal)
- [GNU Stow Package Management](#gnu-stow-package-management)
- [Font Management & Fallback System](#font-management-fallback-system)
- [Editor Configurations](#editor-configurations)
  - [Emacs Configuration](#emacs-configuration)
  - [Helix + Yazelix](#helix-and-yazelix)
  - [Neovim (LazyVim) Configuration](#neovim-configuration)
  - [Editor Management with Stow](#editor-management-with-stow)
- [IntelliJ IDEA Development Utilities](#intellij-idea-development-utilities)
- [Choosing Your Default Shell](#choosing-your-default-shell)

### Architecture & Documentation

- [What's Included](#whats-included)
- [Architecture](#architecture)
- [Documentation](#documentation)
- [Configuration Examples](#configuration-examples)

### Contributing & License

- [Contributing](#contributing)
- [License](#license)
- [Changelog](#changelog)

---

## Installation Guide for macOS

This configuration supports Apple Silicon Macs running macOS Tahoe (26) or later.

### Prerequisites

Make sure you have:

- macOS Monterey (26) or later
- Admin privileges on your Mac
- Internet connection for downloading packages

### 1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

### 2. Install Nix Package Manager

Follow the instructions at [github.com/NixOS/nix-installer](https://github.com/NixOS/nix-installer).

After installation, **open a new terminal session** to make the `nix` command available in your `$PATH`.

### 3. Clone and Initialize Repository

```bash
# Clone the repository
git clone <your-repo-url> ~/darwin-config
cd ~/darwin-config

# Record the repository path so DARWIN_CONFIG_PATH is set for all tools
nix run .#record-config-path

# Make scripts executable
find apps/$(uname -m | sed 's/arm64/aarch64/')-darwin -type f -exec chmod +x {} \;
```

> **Tip:** After recording the path, open a new shell so the `DARWIN_CONFIG_PATH` environment variable is loaded. Every
> helper script expects this variable to be defined and will error if it is missing.

### 4. Configure for Your Environment

Edit `flake.nix` and add your host to the `hostConfigs` section:

```nix
hostConfigs = {
  # Replace with your hostname (run `hostname -s` to check)
  your-hostname = {
    user = "yourusername";  # Your macOS username
    system = "aarch64-darwin";
    defaultShell = "nushell";  # Options: "nushell", "zsh", "fish"
    hostSettings = {
      enablePersonalConfig = true;
    };
  };
};
```

If you want to use a private secrets repository, update the `secrets` input:

```nix
secrets = {
  url = "git+ssh://git@github.com/yourusername/your-secrets-repo.git";
  flake = false;
};
```

> **📝 Note**: Run `git add .` before building to ensure all files are included in the Nix store.

### 5. Optional: Tune Nix Performance for Your Hardware

Edit `system.nix` to optimize build performance based on your Mac's specs.

**Detect your hardware:**

```bash
# Get CPU cores
sysctl -n hw.logicalcpu_max

# Get RAM in GB
echo $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
```

**Update these settings in `system.nix` under `nix.settings`:**

```nix
nix.settings = {
  # Parallel build jobs (recommended: cores × 2 to 4)
  max-jobs = 32;  # Example for 8-core Mac

  # Parallel download jobs (recommended: cores × 2, max 64)
  max-substitution-jobs = 16;

  # Memory thresholds (in bytes)
  # min-free: trigger GC when free RAM drops below this (5% of RAM or 2GB min)
  # max-free: stop GC when free RAM exceeds this (60% of RAM or 5GB min)
  min-free = 2147483648;   # 2GB for 16GB Mac
  max-free = 10737418240;  # 10GB for 16GB Mac
};

# For Macs with 16GB+ RAM and 8+ cores, set to false for faster builds
nix.daemonIOLowPriority = false;
```

**Quick reference by Mac configuration:**

| Mac Config      | max-jobs | max-substitution-jobs | min-free | max-free | daemonIOLowPriority |
|-----------------|----------|-----------------------|----------|----------|---------------------|
| 8 cores, 8GB    | 16       | 16                    | 1GB      | 5GB      | true                |
| 8 cores, 16GB   | 32       | 32                    | 2GB      | 10GB     | false               |
| 10 cores, 32GB  | 40       | 40                    | 2GB      | 19GB     | false               |
| 12 cores, 36GB  | 48       | 48                    | 2GB      | 22GB     | false               |
| 16 cores, 128GB | 64       | 64                    | 6GB      | 77GB     | false               |

### 6. Review and Customize Packages

Before building, review what will be installed:

**Package Configuration Files:**

- `modules/packages.nix` - Nix packages (CLI tools, development tools)
- `stow/aux-scripts/.local/share/bin/{brew-install-all, brew-install-all.xsh}` - Homebrew formulas and casks

**Search for packages:**

- [NixOS Package Search](https://search.nixos.org/packages)
- [Homebrew Cask Search](https://formulae.brew.sh/cask/)
- [Homebrew Formula Search](https://formulae.brew.sh/formula/)

### 7. Optional: Setup SSH Keys and Secrets

If you want to use the full secrets management features:

#### Option A: Create New Keys

```bash
nix run .#create-keys
```

> After creating keys, add the public key to your GitHub account:
>
> ```bash
> cat ~/.ssh/id_ed25519.pub | pbcopy  # Copy to clipboard
> ```

#### Option B: Copy Existing Keys

If you already have existing SSH keys on an USB drive:

```bash
nix run .#copy-keys
```

#### Option C: Check Existing Keys

If you already have keys installed:

```bash
nix run .#check-keys
```

### 8. Test Build Configuration

Before switching to the new configuration, test that it builds successfully:

```bash
nix run .#build
```

> **⚠️ Common Issues:**
>
> **File Conflicts**: If you encounter "Unexpected files in /etc, aborting activation":
>
> ```bash
> # Backup conflicting files (example)
> sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
> sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
> ```

### 9. Deploy Configuration

Once the build succeeds, switch to your new configuration:

```bash
# Build and switch to new configuration
nix run .#build-switch

# OR use aliases (after first successful switch)
nb   # Build configuration
ns   # Build and switch
```

### 10. Deploy Stow Packages

After the initial Nix configuration is deployed, set up additional tools and scripts:

```bash
# Deploy all stow-managed scripts and configurations
manage-stow-packages deploy
```

### 11. Optional: Setup Enhanced Secrets

For full credential management integration:

```bash
# Setup 1Password integration
nix run .#setup-1password-secrets

# OR setup pass as backup credential store
nix run .#setup-pass-secrets

# Check secret management status
secret status
```

## Development Workflow

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
nb && ns  # Build and switch with aliases (syntax not valid in Nushell)
# OR
nb; ns    # (valid in nushell)
# OR
nix run .#build-switch
```

### Updating Software Versions

To get the latest software versions and package updates:

```bash
# Update flake lock file to latest versions
nix flake update

# Update specific input (optional)
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# After updating, rebuild and switch
nb && ns
# OR
nb; ns
# OR simply
ns
```

**What `nix flake update` does:**

- Updates `flake.lock` with latest versions of nixpkgs, home-manager, and other inputs
- Gets security updates and new package versions
- May introduce breaking changes, so test after updating
- Equivalent to updating your "package manager" in other systems

### System Maintenance

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

### Package Pinning System

The `smart-gc` utility includes a package pinning system to prevent
accidental removal of essential packages during garbage
collection. This system creates GC roots that keep specific packages
and their dependencies in the Nix store.

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

The essential packages list is defined in `smart-gc.nu`. Currently,
most packages are commented out by default to avoid over-pinning:

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
2. **Essential Packages**: Uses `nix build --no-link print-out-paths` to realize packages and create implicit GC roots
3. **GC Root Storage**: Stores roots in `/nix/var/nix/gcroots/` where the garbage collector respects them

This approach ensures that while garbage collection won't remove pinned packages, the normal update and rebuild
processes work exactly as expected.

## Available Nix Apps

### Core Build Commands

| Command                  | Description                           |
|--------------------------|---------------------------------------|
| `nix run .#build`        | Build the configuration               |
| `nix run .#build-switch` | Build and switch to new configuration |
| `nix run .#apply`        | Apply configuration changes           |
| `nix run .#rollback`     | Rollback to previous generation       |

Note on evaluation mode for `nb`/`ns`:
- Default: impure evaluation for compatibility with host-specific tooling that reads files from the working tree.
- Force pure: add `--pure` or set `NS_IMPURE=0`.
- Explicit impure: add `--impure` or set `NS_IMPURE=1`.

Tip: run `ns --help` or `nb --help` for all options.

### Configuration Management

| Command                              | Description                                        |
|--------------------------------------|----------------------------------------------------|
| `nix run .#add-host`                 | Add new host configuration to flake.nix            |
| `nix run .#configure-user`           | Configure for different user/hostname combinations |

### Security & Secrets

| Command                             | Description                                     |
|-------------------------------------|-------------------------------------------------|
| `nix run .#setup-1password-secrets` | Set up 1Password for secure git credentials     |
| `nix run .#setup-pass-secrets`      | Set up pass for secure git credentials          |
| `nix run .#check-keys`              | Check if required SSH keys exist                |
| `nix run .#create-keys`             | Create SSH keys (id_ed25519, id_ed25519_agenix) |
| `nix run .#copy-keys`               | Copy SSH keys from mounted USB to ~/.ssh        |

### Enhanced Secret Management

| Command                  | Description                                        |
|--------------------------|----------------------------------------------------|
| `secret status`          | Show status of all credential systems              |
| `secret list`            | List all available agenix secrets                  |
| `secret create <name>`   | Create new agenix secret                           |
| `secret edit <name>`     | Edit existing agenix secret                        |
| `secret show <name>`     | Display decrypted secret content                   |
| `secret rekey`           | Re-encrypt all agenix secrets with current keys    |
| `secret sync-git`        | Update git configs from 1Password/pass credentials |
| `secret op-get <item>`   | Get 1Password item                                 |
| `secret pass-get <path>` | Get pass entry                                     |
| `backup-secrets`         | Backup all secrets, keys, and configurations       |
| `setup-secrets-repo`     | Clone and setup secrets repository                 |

### Repository Management

| Command                   | Description                                  |
|---------------------------|----------------------------------------------|
| `nix run .#sanitize-repo` | Sanitize repository of sensitive information |

### GNU Stow Package Management

| Command                       | Description                                                   |
|-------------------------------|---------------------------------------------------------------|
| `manage-stow-packages deploy` | Deploy all stow-managed scripts and configurations            |
| `manage-stow-packages remove` | Remove all stow-managed symlinks                              |
| `stow -t ~ PACKAGE`           | Deploy specific stow package (e.g., lazyvim, raycast-scripts) |
| `stow -D -t ~ PACKAGE`        | Remove specific stow package                                  |
| `manage-cargo-tools install`  | Install/update Rust/Cargo tools from configuration            |
| `manage-nodejs-tools install` | Install/update Node.js tools and toolchain                    |
| `manage-dotnet-tools install` | Install/update .NET SDK and global tools                      |

### Development Utilities

| Command                          | Description                                             |
|----------------------------------|---------------------------------------------------------|
| `cleanup-intellij [project]`     | Clean IntelliJ IDEA caches and fix broken state         |
| `emacsclient-gui`                | Launch Emacs GUI client with proper macOS integration   |

## Key Features

- **🔄 Multi-User/Multi-Host**: Easily configure for different users and machines
- **🔐 Hybrid Secrets Management**: Multi-layered security with agenix, 1Password, and pass
  - **agenix**: SSH keys, certificates, system secrets (encrypted with age)
  - **1Password**: User credentials, API tokens (authenticated, enterprise-grade)
  - **pass**: Backup credential store (offline, GPG-encrypted)
  - **Unified CLI**: Single `secret` command for all credential systems
- **📦 Package Management**: Nix packages + Homebrew integration
- **✨ Emacs Integration**: Stock emacs-overlay build with niceties:
  - **Helper Commands**: `e`, `t`, `et`, `emacsclient-gui`
  - **macOS Integration**: Proper window management and GUI support
  - **Ghostty Terminal Support**: Full xterm-ghostty terminfo integration
  - **Catppuccin Theming**: Unified theme management across applications (not perfect nor global)
- **🐚 Advanced Shell Configuration**: Full support for Nushell, Zsh, Fish, and Xonsh:
  - **Consistent Experience**: Same aliases, PATH, and tools across all primary shells
  - **Smart Switching**: Easy shell changes via simple configuration updates
  - **Modern Features**: Starship prompts, Zoxide navigation across all shells
  - **Python Integration**: Native Python scripting support with Xonsh
- **🔧 Development Tools**: Complete development environment with LSPs, formatters, etc.
- **🔒 Security First**: Automated backups, key rotation, and credential synchronization

## Ghostty Terminal

This configuration uses [**Ghostty**](https://ghostty.org/) as the preferred terminal emulator, chosen over alternatives
like WezTerm, Kitty, and iTerm2 for its performance, native macOS integration, and clean design.

### Why Ghostty?

- **Native Performance**: Built with Zig for exceptional speed and low latency
- **macOS Integration**: First-class support for macOS features and behaviors
- **GPU Acceleration**: Smooth rendering with minimal resource usage
- **Modern Features**: Full Unicode support, ligatures, and true color
- **Simple Configuration**: Plain text config files, no complex setup required

### Configuration

Ghostty configuration is managed via the stow system:

```bash
# Deploy Ghostty configuration
cd ~/darwin-config/stow
stow -t ~ ghostty

# Or deploy all stow packages at once
manage-stow-packages deploy
```

**Configuration file**: `~/.config/ghostty/overrides.conf` (symlinked from stow)

Current settings include:
- **Font**: MonoLisa Variable Nerd Font at 16pt with thickening
- **Theme**: Catppuccin Mocha
- **Scrollback**: Large buffer
- **Terminal**: xterm-ghostty terminfo for full compatibility

### Customization

Edit the source configuration at `~/darwin-config/stow/ghostty/.config/ghostty/overrides.conf` and rerun stow to apply
changes. See the [Ghostty documentation](https://ghostty.org/docs) for all available options.

## GNU Stow Package Management

This repository uses **GNU Stow** to manage auxiliary scripts, dotfiles, and tools that are difficult to embed directly
in Nix configuration. Stow creates symlinks from your home directory to files in the repository, providing version
control and easy deployment.

### Available Stow Packages

| Package                     | Description                            | Target Location       |
|-----------------------------|----------------------------------------|-----------------------|
| **aux-scripts**             | Utility scripts and tools              | `~/.local/share/bin/` |
| **lazyvim**                 | Neovim LazyVim configuration           | `~/.config/nvim/`     |
| **zed**                     | Zed editor configuration               | `~/.config/zed/`      |
| **zellij-theme-management** | Zellij theme switcher + helpers        | `~/.local/bin/`       |
| **kitty**                   | Kitty terminal themes + scripts        | `~/.config/kitty/`    |
| **ghostty**                 | Ghostty terminal configuration         | `~/.config/ghostty/`  |
| **aerospace**               | AeroSpace tiling window manager config | `~/`                  |
| **raycast-scripts**         | Raycast automation scripts             | `~/.local/share/bin/` |
| **nix-scripts**             | Nix-related utility scripts            | `~/.local/share/bin/` |
| **cargo-tools**             | Rust/Cargo tools management            | `~/.local/share/bin/` |
| **nodejs-tools**            | Node.js tools and toolchain management | `~/.local/share/bin/` |
| **dotnet-tools**            | .NET SDK and global tools management   | `~/.local/share/bin/` |

### Quick Stow Commands

```bash
# Navigate to stow directory
cd ~/darwin-config/stow

# Deploy all packages at once
manage-stow-packages deploy

# Deploy specific packages
stow -t ~ lazyvim                # Deploy LazyVim config
stow -t ~ zed                    # Deploy Zed config
stow -t ~ aux-scripts            # Deploy utility scripts

# Remove packages
stow -D -t ~ lazyvim            # Remove LazyVim config
manage-stow-packages remove     # Remove all packages
```

### Tool Management Scripts

After deploying the appropriate stow packages, these management commands become available:

```bash
# Development toolchain management
manage-cargo-tools install    # Install Rust tools from cargo-tools.toml
manage-nodejs-tools install   # Install Node.js toolchain from nodejs-tools.toml
manage-dotnet-tools install   # Install .NET SDK from dotnet-tools.toml

# Configuration management
# (Bring your own Emacs config; no Doom helper script is provided)
```

### When to Use Stow vs. Nix

**Use Stow for:**

- Complex shell scripts that are hard to escape in Nix
- Editor configurations with many files (LazyVim, Zed, custom Emacs setups)
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

## Font Management & Fallback System

This configuration includes an intelligent font fallback system that provides seamless support for both commercial and
open-source programming fonts.

### Font Hierarchy

The system automatically detects available fonts and uses them in this priority order:

1. **MonoLisa Variable** (commercial) - Premium programming font with extensive ligature support
2. **PragmataPro Liga** (commercial) - Compact, feature-rich programming font
3. **JetBrains Mono** (open source) - High-quality fallback with excellent readability
4. **System fonts** (SF Mono, monospace) - Final fallback

### Font Detection Utility

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

### Application Integration

#### Emacs

See [Emacs font config](./stow/emacs/.emacs.d/my/my-fonts.el) for font configuration for Emacs.

#### Ghostty Terminal

- **Base configuration**: Font fallback built into `~/.config/ghostty/config`
- **Runtime overrides**: `ghostty-config` writes `~/.config/ghostty/overrides.conf` which is loaded via `config-file`
- **Runtime switching**: Use `ghostty-config font "Font Name"` to switch fonts
- **Automatic fallback**: Missing fonts don't break the configuration

### Available Font Commands

| Command                           | Description                                |
|-----------------------------------|--------------------------------------------|
| `detect-fonts status`             | Show availability of all programming fonts |
| `detect-fonts emacs-font`         | Get recommended font key for Emacs         |
| `detect-fonts ghostty-font`       | Get recommended font name for terminals    |
| `ghostty-config font "Font Name"` | Switch terminal font (with restart)        |
| `ghostty-config list`             | Show all available font options            |

### Font Features

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

### How It Works

1. **Detection**: System scans available fonts using `fc-list`
2. **Fallback Chain**: Applications automatically use the best available font
3. **Configuration**: Each app includes font-specific optimizations
4. **Runtime Switching**: Tools allow manual font switching when desired

### For New Installations

If you're setting up on a system without commercial fonts:

1. The system automatically detects JetBrains Mono is available
2. Emacs, Ghostty, and other apps default to JetBrains Mono
3. All ligatures and features work seamlessly
4. You can later add commercial fonts and switch to them using `F8` in Emacs

### Benefits

- **Zero Configuration**: Works out of the box on any system
- **Graceful Degradation**: Missing fonts don't break anything
- **Consistent Experience**: Same ligatures and features across fonts
- **Easy Migration**: Add commercial fonts later without reconfiguration
- **Developer Friendly**: Optimized for programming with proper ligature support

## Editor Configurations

This repository provides ready-to-use configurations for multiple editors, managed through a combination of Nix (Home
Manager) and GNU Stow.

### Emacs Configuration

This repository assumes Emacs is installed via homebrew using:
```
brew install --cask jimeh/emacs-builds/emacs-app-nightly  
```

For the Emacs configuration itself, see under [emacs-config](./stow/emacs/.emacs.d/).

### Helix and Yazelix

[Helix](https://helix-editor.com/) is a post-modern modal text editor with built-in LSP support, tree-sitter
integration, and multiple cursors. This configuration uses a **bleeding-edge build** of Helix for the latest features
and fixes. The fork that is being used is at [gj1118/helix](https://github.com/gj1118/helix).

[Zellij](https://github.com/zellij-org/zellij) is
> a workspace aimed at developers, ops-oriented people and anyone who loves the terminal. Similar programs are sometimes called "Terminal Multiplexers"

I use [this nix-friendly repo](https://github.com/oscarvarto/zellij-nix) to point to a recent commit of Zellij (it's
built from source, but gives you a bleeding-edge build of Zellij).

[Yazelix](https://github.com/luccahuguet/yazelix) integrates Helix with Zellij (terminal multiplexer) and Yazi (file
manager) for a complete IDE-like experience. **This configuration uses a customized Yazelix integration** that departs
from upstream development:

- **No devenv shell** — uses Home Manager and flakes directly
- **Custom Zellij layouts** — tailored for personal workflow
- **Nix-managed configuration** — reproducible across machines

#### Why Helix?

- **Built-in LSP**: No plugin setup required — language servers work out of the box
- **Tree-sitter**: Syntax highlighting and text objects powered by tree-sitter
- **Multiple Cursors**: First-class support for multiple selections
- **Modal Editing**: Kakoune-inspired selection-first model
- **Fast**: Written in Rust, instant startup
- **Minimal Configuration**: Sensible defaults, less time tweaking

#### Yazelix Features

- **Zellij Integration**: Terminal multiplexer with persistent sessions
- **Yazi File Manager**: Fast, keyboard-driven file navigation
- **Unified Workflow**: Seamless switching between editor, terminal, and files
- **Theme Synchronization**: Consistent theming across all components

#### Configuration

Helix configuration is managed via Home Manager in `modules/home-manager.nix`:

```nix
programs.helix = {
  enable = true;
  package = inputs.helix.packages.${pkgs.system}.helix;  # Bleeding edge
  # ... settings
};
```

Zellij layouts and Yazelix integration are in the Nix configuration,
not requiring separate stow packages.

#### Quick Start

```bash
# Helix is available immediately after nix build-switch
hx                    # Start Helix
hx .                  # Open current directory
hx --health           # Check LSP and feature status

# Yazelix (Zellij + Helix + Yazi)
zellij                # Start with default layout
```

### Neovim Configuration

A modern Neovim configuration based on LazyVim with sensible defaults, extensive plugin ecosystem, and enhanced
Lisp/Elisp support.

#### Quick Setup

```bash
# 1. Neovim is already installed via Nix (see modules/packages.nix)

# 2. Deploy LazyVim configuration
cd ~/darwin-config/stow
stow -t ~ lazyvim
# OR: manage-stow-packages deploy lazyvim

# 3. Start Neovim (plugins auto-install on first run)
nvim
```

#### Configuration Structure

```
~/.config/nvim/  (symlinked from ~/darwin-config/stow/lazyvim/.config/nvim/)
├── init.lua         # Main configuration entry point
└── lua/
    ├── config/                     # Core configuration
    │   ├── autocmds.lua
    │   ├── keymaps.lua
    │   ├── lazy.lua                # Plugin manager setup
    │   └── options.lua
    └── plugins/
        ├── colorscheme.lua
        ├── elisp.lua
        ├── kotlin.lua
        ├── lazyextras-command.lua
        ├── lint.lua
        ├── lisp.lua
        ├── markdown_fill.lua       # Emacs-like fill for Markdown
        ├── nixd.lua
        ├── obsidian.lua
        ├── orgmode.lua
        ├── python.lua
        ├── terminal.lua
        ├── treesitter.lua
        └── whitespace.lua          # Emacs-like fill for Markdown
```

#### Key Features

- **📦 Plugin Management**: Lazy.nvim with automatic plugin installation
- **🛠️ LSP Integration**: Built-in language server support
- **🎨 Modern UI**: Beautiful statusline, bufferline, themes
- **⚡ Performance**: Lazy loading, fast startup
- **🔧 Extensible**: Easy to add custom plugins and configurations
- **👾 Lisp Support**: Enhanced support for Lisp dialects including Emacs Lisp
- **🎯 Structural Editing**: Parinfer for automatic parenthesis management

#### Available Commands

| Command             | Description                             |
|---------------------|-----------------------------------------|
| `nvim`              | Start Neovim with LazyVim configuration |
| `nvim +Lazy`        | Open plugin manager                     |
| `nvim +Mason`       | Open LSP installer                      |
| `nvim +checkhealth` | Check configuration health              |

#### Basic Usage

**Key Bindings (LazyVim defaults):**

- `<leader>` = `<Space>`
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>e` - Toggle file explorer
- `<leader>gg` - Open lazygit
- `<leader>l` - LSP commands

#### Whitespace Cleanup (On-Demand)

- Keymaps:
  - `<leader>cw` — Trim trailing whitespace and final blank lines in the buffer
  - `<leader>cT` — Untabify (tabs → spaces) using current buffer indent settings
  - `<leader>ct` — Tabify (spaces → tabs) using current buffer indent settings
- Behavior:
  - No auto-trim on save; all actions are on-demand
  - Respects EditorConfig indentation for each filetype
  - Whitespace highlighting is disabled in dashboards/special buffers (alpha, lazy, mason, NvimTree, TelescopePrompt, etc.)

#### Markdown Fill (Emacs‑Like)

- Commands and keymaps (Markdown only):
  - `:FillParagraph` or `<leader>fm` — Reflow current paragraph to `textwidth` (default 80)
  - Visual select → `:FillRegion` or `<leader>fr` — Reflow selected region
  - `:FillBuffer` or `<leader>fB` — Reflow entire buffer
- Behavior:
  - Skips fenced (```/~~~) and indented code blocks
  - Uses `gq` formatting; no auto-wrap while typing (formatoptions removes `t`, keeps `q`)
  - `textwidth` defaults to 80 for Markdown; adjust per file/buffer if needed

Tip — Adjust Markdown wrap width

- One-off buffer: `:setlocal textwidth=88` then use `:FillParagraph`/`:FillRegion`/`:FillBuffer`.
- Session/global: `:lua vim.g.markdown_fill_textwidth = 88` (put in any user Lua file loaded at startup, e.g.,
  `~/.config/nvim/lua/config/options.lua` or a small plugin file). The fill commands use this value for `textwidth` when
  opening Markdown.

#### EditorConfig (Global)

- Managed via Home Manager; applies across editors and tools.
- Defaults:
  - Global: UTF‑8, LF, final newline; no auto-trim; 2‑space indent
  - Makefile/Go: tabs; Python: 4 spaces; Nix/Lua/Nu/Web/Shell: 2 spaces
  - See `modules/home-manager.nix` → `editorconfig.settings` for full list

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

### Editor Management with Stow

Both editor configurations use the stow system for deployment and management.

#### Deploying Editor Configurations

```bash
# Deploy both editors
manage-stow-packages deploy

# Deploy specific editor
stow -t ~ lazyvim       # Deploy LazyVim config
stow -t ~ zed           # Deploy Zed config

# Check deployment status
manage-stow-packages status
```

#### Removing Editor Configurations

```bash
# Remove specific editor config (preserves files)
stow -D -t ~ lazyvim
stow -D -t ~ zed

# Remove all stow packages
manage-stow-packages remove
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
   - Update `manage-stow-packages` to include new package
   - Add documentation to package README.md

### Editor Notes

- **Emacs**: Extensive customization, org-mode, magit, Elisp ecosystem
- **Helix + Yazelix**: Modern modal editing, built-in LSP, minimal configuration, IDE-like workflow with
  Zellij and Yazi
- **LazyVim/Neovim**: Fast startup, Lua configuration, excellent terminal integration

## IntelliJ IDEA Development Utilities

### IntelliJ Cache Cleanup Tool

The `cleanup-intellij` script is a powerful utility for fixing broken IntelliJ IDEA states that can interfere with
development. IntelliJ often accumulates corrupt caches, project files, and configuration states that cause issues like:

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

| Option                          | Description                                           |
|---------------------------------|-------------------------------------------------------|
| `cleanup-intellij`              | Clean all IntelliJ system caches                      |
| `cleanup-intellij <project>`    | Clean all caches + specific project files             |
| `cleanup-intellij -p <project>` | Clean only project-specific files (.idea, .iml, etc.) |
| `cleanup-intellij -s`           | Clean only system caches and application data         |
| `cleanup-intellij -g`           | **Aggressive**: Clean ALL project files system-wide   |
| `cleanup-intellij -h`           | Show help and usage examples                          |

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

This tool is particularly useful in JVM development environments where IntelliJ's complex project models can become
corrupted, especially when working with large codebases, multi-module projects, or frequently switching between branches
with different project structures.

## Choosing Your Default Shell

To keep things easy, choose Zsh as your system/user shell. You could configure your terminal to use one of the supported
shells by default. This configuration provides support for **Nushell**, **Zsh**, **Fish**, and **Xonsh**.

### Shell Support Levels

| Shell       | Support Level | Description                                           | Best For                                             |
|-------------|---------------|-------------------------------------------------------|------------------------------------------------------|
| **Nushell** | ⭐ Full       | Full integration with all features                    | Data manipulation, pipelines, modern workflows       |
| **Zsh**     | ⭐ Full       | Full integration, extensive plugin support            | Power users, legacy compatibility, extensive plugins |
| **Fish**    | ⭐ Full       | Full integration, user-friendly syntax                | Interactive use, beginners, auto-suggestions         |
| **Xonsh**   | ⭐ Full       | Full tool integrations, Python scripting capabilities | Python developers, shell automation, advanced script |

### ✅ Xonsh Support

**Xonsh is fully supported** with the unique ability to execute Python code directly in the shell environment. This
makes it particularly powerful for Python developers and automation tasks.

#### Setting Up Xonsh

To use Xonsh, you first need to install the Python environment using `pixi`:

```bash
# Install the Python environment (one-time setup, run from Nushell)
pixi-gt install

# Or manually:
cd ~/darwin-config/python-env
pixi install
```

#### Starting Xonsh

After the environment is installed, use the `xsh` alias from any supported shell (Nushell, Zsh, or Fish):

```bash
# Quick start xonsh from any shell
xsh
```

> **Note:** The `xsh` alias runs `pixi run xonsh` with the correct manifest path. This is the recommended way to start
> xonsh as it automatically uses the pixi environment without needing to manually activate it.

#### Xonsh Advantages

- **🐍 Native Python Integration**: Execute Python code directly in shell (e.g., `print(f"Hello {2+2}")`)
- **📦 Full Tool Integration**: Starship, Zoxide with complete functionality
- **🎨 Dynamic Theming**: Automatically adapts colors based on system light/dark mode
- **⚡ Complete Functionality**: All essential shell operations and modern CLI tools work correctly
- **🔧 Robust Package Management**: Uses pixi for fast, reliable Python package management (conda-forge + PyPI)

#### What Works

**Core Integrations:**
- ✅ **Starship**: Full prompt integration with Git status, themes, and customization
- ✅ **Zoxide**: Smart directory jumping (`z` command) with full functionality
- ✅ **Modern Aliases**: Complete set including `eza`, `bat`, `fd`, `rg`, and other modern CLI tools
- ✅ **PATH Management**: Full PATH configuration with all development tools

**Advanced Features:**
- ✅ **Python Environment**: Integrated with pixi for consistent package management (conda-forge + PyPI)
- ✅ **Error Handling**: Graceful degradation when tools are unavailable
- ✅ **Theme Support**: Automatic light/dark mode detection and color scheme adaptation

#### Using Xonsh

**Starting Xonsh:**
```bash
# First, ensure you're in the pixi environment
cd ~/darwin-config/python-env && pixi shell

# Then launch xonsh
xonsh
```

**Python Integration Examples:**
```python
# Execute Python directly in shell
ls $(Path.home() / "Documents")   # Python pathlib in shell commands
[f"file_{i}.txt" for i in range(3)]  # List comprehensions
import json; json.dumps({"key": "value"})  # Import and use modules
```

**Ready-to-Use Experience:**
```bash
# After running `pixi shell` in python-env directory
xonsh  # Launch xonsh - everything works immediately!
```

**All integrations work out of the box:**
- ✅ **Starship**: Beautiful prompts with Git integration
- ✅ **Zoxide**: Smart directory jumping (`z` command)
- ✅ **Modern aliases**: Complete set of `eza`, `bat`, `fd`, `rg` and other CLI tools
- ✅ **Development tools**: Full PATH with all development environments

#### Configuration

Xonsh configuration is managed in `modules/xonsh/`:
- **Main config**: `modules/xonsh/rc.xsh` - Shell behavior and tool integrations
- **Xontribs**

**Note**: Xonsh is not available as a `defaultShell` option. Access it by running `xsh` from your primary shell.

### Setting Your Default Shell

#### For New Installations

When adding a new host to your configuration, specify the `defaultShell` option in `flake.nix`:

```nix
hostConfigs = {
  your-hostname = {
    user = "youruser";
    system = "aarch64-darwin";
    defaultShell = "zsh";  # (recommended)
    hostSettings = {
      enablePersonalConfig = true;
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
     defaultShell = "fish";  # Change to your preferred shell ("zsh" recommended)
     hostSettings = {
       # ... existing settings
     };
   };
   ```

2. **Rebuild your system:**

   ```bash
   nb && ns  # Build and switch
   # OR simply
   ns
   ```

### Shell Features

#### All Shells - Full Features

All supported shells (Nushell, Zsh, Fish, Xonsh) include:

- **Starship Prompt**: Modern, fast prompt with git integration
- **Zoxide**: Smart directory jumping with `z` command
- **Yazi**: File manager integration
- **Consistent Aliases**: Complete set of shortcuts
- **PATH Management**: Full PATH configuration with all integrations
- **Development Tools**: All tools with shell integrations

#### Xonsh Shell - Additional Features

- **Starship Prompt**: Complete prompt integration with Git status and themes
- **Python Integration**: Native Python code execution in shell environment
- **Full Tool Integrations**: Zoxide, Starship working perfectly
- **Dynamic Theming**: Automatic light/dark color scheme adaptation
- **Modern Aliases**: Complete set of shortcuts (`eza`, `bat`, `fd`, `rg`)
- **PATH Management**: Full PATH configuration with all development tools

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

**Zsh Features:**

```bash
# Advanced completion system
# Glob patterns and extended matching
# Plugin ecosystem compatibility
# Customizable prompt systems
```

**Xonsh Features:**

```python
# Native Python integration
print(f"Current directory: {Path.cwd()}")
files = [f for f in Path('.').iterdir() if f.suffix == '.py']

# Python libraries in shell
import requests
response = requests.get('https://api.github.com/user').json()

# Subprocess with Python
result = $(grep -r "pattern" .)
lines = result.split('\n')
```

**Fish Features:**

```bash
# User-friendly syntax
set myvar "hello"

# Auto-suggestions and completions out of the box
# Syntax highlighting built-in
# Configuration managed declaratively via Nix
```

### Available Shell Commands

#### Common Aliases (All Shells)

| Alias    | Command                                                          | Description                           |
|----------|------------------------------------------------------------------|---------------------------------------|
| `nb`     | `nix run .#build`                                                | Build darwin configuration            |
| `ns`     | `nix run .#build-switch`                                         | Build and switch configuration        |
| `gp`     | `git fetch --all -p; git pull; git submodule update --recursive` | Git pull with submodules              |
| `search` | `rg -p --glob '!node_modules/*'`                                 | Ripgrep search excluding node_modules |
| `edd`    | `emacs-service-toggle start`                                     | Start Emacs daemon via LaunchAgent    |

Impure/pure switches for nb/ns:
- Default: impure evaluation for compatibility with host-specific tooling that reads from the working tree.
- Force pure: `ns --pure` or `NS_IMPURE=0 ns` (same for `nb`).
- Explicit impure: `ns --impure` or `NS_IMPURE=1 ns`.

#### Shell Configuration Shortcuts

| Command | Shell | Description            |
|---------|-------|------------------------|
| `nnc`   | All   | Edit Nushell config.nu |
| `nne`   | All   | Edit Nushell env.nu    |
| `tg`    | All   | Edit terminal config   |

### Switching Between Shells

#### Quick Shell Testing

```bash
# Try different shells temporarily
nu      # Start nushell session
zsh     # Start zsh session
exit    # Return to default shell
```

#### Changing Default Shell

1. **Update flake.nix:**

   ```nix
   defaultShell = "nushell";  # Options: "nushell", "zsh", "fish", "xonsh"
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

### Advanced Shell Configuration

#### Customizing Shell Behavior

Each shell's configuration can be customized in specific files:

**Nushell**: `modules/nushell/config.nu` and `modules/nushell/env.nu`
**Zsh**: `modules/shell-config.nix` and `modules/zsh-darwin.nix`

#### Adding Custom Aliases

Edit the appropriate configuration file for your shell:

**For Nushell** (`modules/nushell/config.nu`):

```nushell
# Add custom aliases
alias myalias = "your-command"
```

**For Zsh** (`modules/shell-config.nix`):

```nix
initContent = lib.mkAfter ''
  alias myalias="your-command"
'';
```

### Shell Recommendations

**Choose Nushell if you:**

- Work with structured data (JSON, CSV, XML)
- Like modern, consistent command syntax
- Want powerful data manipulation pipelines
- Prefer type safety and structured output
- Want full integration with all development tools

**Choose Zsh if you:**

- Need maximum compatibility with bash scripts
- Want extensive plugin ecosystem (oh-my-zsh, etc.)
- Prefer traditional Unix shell behavior
- Have existing zsh configurations to port
- Want full integration with all development tools

**Choose Xonsh if you:**

- Are a Python developer who wants native Python in shell
- Need to write complex shell automation using Python libraries
- Want to leverage Python's ecosystem directly in shell environment
- Prefer structured data handling with Python's tools
- Want a modern shell with full tool integration and Python power

**Choose Fish if you:**

- Want a user-friendly shell with great defaults out of the box
- Appreciate auto-suggestions and syntax highlighting
- Prefer simple, readable syntax
- Shell configuration is managed by Nix (declarative and reproducible)

### PATH and Environment Management

All shells use the centralized PATH configuration from `modules/path-config.nix`. This ensures:

- **Consistent PATH**: Same paths across all shells
- **Priority Control**: Your tools take precedence
- **Tool Integration**: Automatic integration with development tools
- **Override Capability**: Your configuration overrides mise, homebrew, etc.

See [PATH Management Documentation](modules/PATH-MANAGEMENT.md) for detailed PATH customization.

### 🔍 Troubleshooting Shell Issues

This is **not* exhaustive.

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

# Test configuration syntax
# For nushell:
nu --config modules/nushell/config.nu --commands "exit"
```

### Shell Integration Tips

- **Emacs Integration**: The default shell setting automatically configures vterm and shell-mode
- **Terminal Integration**: All shells work seamlessly with Ghostty and other terminals
- **Script Compatibility**: Shell scripts in this repo use bash for maximum compatibility
- **Interactive vs Script**: Your default shell affects interactive sessions, not system scripts

## What's Included

### Core Tools

- **Nix Package Manager** with flakes
- **Home Manager** for user configuration
- **Homebrew** integration for GUI apps
- **Stow** for dotfiles management

### Development Environment

- **Languages**: Rust, Go, Node.js, Python, Java, C++
- **Fast Editor**: [Helix](https://helix-editor.com/) (bleeding edge) with [Yazelix](https://github.com/luccahuguet/yazelix) integration
- **Mature Editors**: Emacs, Neovim (LazyVim)
- **Version Control**: Git with smart conditional configs
- **Terminal Emulator**: [Ghostty](https://ghostty.org/) (besides WezTerm, Kitty)
- **Shells**: Nushell, Zsh, Fish, Xonsh with beautiful prompts

### macOS Integration

- **System Preferences**: Dock, Finder, trackpad settings
- **GUI Applications**: Development tools, productivity apps
- **Fonts**: Programming fonts with intelligent fallback system
- **Services**: LaunchAgent configurations (Emacs daemon, Yazelix nightly updater)

## Architecture

```
flake.nix              # Main flake with inputs, hostConfigs, and apps
├── system.nix         # System-level macOS configuration
├── apps/
│   └── aarch64-darwin/
├── modules/           # Modular configuration components
│   ├── home-manager.nix   # User environment & programs
│   ├── packages.nix       # Nix packages
│   ├── secrets.nix        # Age-encrypted secrets configuration
│   ├── secure-credentials.nix # 1Password/pass integration
│   ├── enhanced-secrets.nix   # Unified secret management CLI
│   ├── overlays.nix       # Nixpkgs configuration (no custom overlays)
│   ├── dock/              # macOS Dock configuration
│   ├── nushell/           # Nushell shell configuration
│   ├── elisp-formatter/   # Emacs Lisp formatting tool
│   ├── scripts/nu/        # Nushell utility scripts
│   └── xonsh/
├── scripts/           # Configuration helper scripts
│   ├── configure-user.sh  # User/hostname configuration
│   ├── add-host.sh        # Add new host to flake
│   └── setup-*-secrets.sh # Secrets management scripts
└── stow/              # GNU Stow packages for dotfiles
    ├── aux-scripts/        # Helper scripts deployed to ~/.local/share/bin
    ├── emacs/              # Configuration using elpaca
    ├── lazyvim/            # Configuration
    ├── zed/                # Configuration
    ├── zellij-theme-management/ # Zellij theme switcher scripts
    ├── kitty/              # Kitty terminal theme + helper scripts
    ├── raycast-scripts/    # Raycast automation scripts
    ├── nix-scripts/        # Nix-related utilities
    └── .../                # Additional tool configurations
```

## Documentation

- **[Multi-User Setup Guide](MULTI-USER-SETUP.md)** - Comprehensive guide for adapting to different users and machines
- **[Secrets Management Guide](SECRETS-MANAGEMENT.md)** - Secure credential management with 1Password and pass
- **[Scripts Documentation](scripts/)** - Details on the automation tools

## Configuration Examples

Unfortunately, using a non-POSIX shell as default shell, is somewhat problematic. Sadly, a lot of software default to
the lowest common denominator: bash. So, to simplify stuff, use zsh as your system shell. Configure your terminal to use
your favorite shell, and enjoy that when possible.

### Setup with Zsh (Full Support - Recommended)

```nix
secondary-mac = {
  user = "alice";
  system = "aarch64-darwin";
  defaultShell = "zsh";      # Traditional shell with full integrations
  hostSettings = {
    enablePersonalConfig = true;
  };
};
```

### Setup with Fish

```nix
fish-system = {
  user = "bob";
  system = "aarch64-darwin";
  defaultShell = "fish";     # User-friendly shell with great defaults
  hostSettings = {
    enablePersonalConfig = true;
  };
};
```

## Contributing

This configuration is designed to be a starting point. Feel free to:

- Fork and customize for your needs
- Submit issues for bugs or improvements
- Share your own modifications and enhancements

## License

This configuration is provided as-is. Feel free to use, modify, and distribute according to your needs.

I am using a lot of different software in this configuration, and putting all appropriate the licenses here might be
impractical (e.g. I'm using a modified version of Yazelix source code, which is Apache-2.0 licensed). Please forgive me
if I'm making a mistake or missing something.

## Changelog

### Jan 2026

- Initial commit.
