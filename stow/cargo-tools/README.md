# Cargo Tools Management

This stow package provides version-controlled management of cargo-installed Rust tools. While stow doesn't directly manage the binaries (cargo does that), it tracks which tools you want installed and provides easy installation/restoration capabilities.

## How It Works

1. **Configuration Tracking**: `cargo-tools.toml` tracks which cargo packages you want installed
2. **Management Script**: `manage-cargo-tools` provides commands to install, update, and manage tools
3. **Version Control**: Your cargo tool configuration is tracked in git with your darwin-config
4. **System Restoration**: After a system wipe, easily reinstall all your cargo tools

## Files

- `cargo-tools.toml` - Configuration file listing desired packages
- `.local/share/bin/manage-cargo-tools` - Management script (deployed via stow)

## Usage

### Deploy the management script:
```bash
cd ~/darwin-config/stow
stow cargo-tools
```

### Install all configured packages:
```bash
manage-cargo-tools install
```

### Check status of configured packages:
```bash
manage-cargo-tools status
```

### List all cargo-installed packages:
```bash
manage-cargo-tools installed
```

### Update all packages:
```bash
manage-cargo-tools update
```

### Add a new package to configuration:
```bash
manage-cargo-tools add
```

## Configuration Format

Edit `cargo-tools.toml` to add/remove packages:

```toml
[packages]
# Regular crates.io packages
ripgrep = { version = "*", description = "Fast grep alternative" }
fd-find = { version = "8.0.0", description = "Fast find alternative" }

# Git-based packages
some-tool = { git = "https://github.com/user/repo", description = "Tool from git" }

[settings]
auto_update = true
use_locked = false
```

## Benefits

1. **Version Control**: Your cargo tool preferences are tracked with your dotfiles
2. **Easy Restoration**: After system restore, one command reinstalls all tools
3. **Documentation**: Each tool has a description explaining its purpose
4. **Flexibility**: Supports both crates.io and git-based packages
5. **Integration**: Works seamlessly with the broader stow-based script management

## System Restoration Workflow

After a system wipe:
1. Install Rust/Cargo
2. Clone your darwin-config
3. Run `cd ~/darwin-config/stow && stow cargo-tools`
4. Run `manage-cargo-tools install`

All your cargo tools will be automatically restored!
