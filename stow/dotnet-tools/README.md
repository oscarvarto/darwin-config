# .NET Tools Management

This stow package provides version-controlled management of .NET SDKs and global tools.

## How It Works

1. **Configuration Tracking**: `dotnet-tools.toml` tracks your desired .NET global tools and SDK version.
2. **Management Script**: `manage-dotnet-tools` provides commands to install, update, and manage tools.
3. **Version Control**: Your .NET tool configuration is tracked in git with your darwin-config.
4. **System Restoration**: After a system wipe, easily reinstall your entire .NET environment.

## Files

- `dotnet-tools.toml` - Configuration file listing desired SDK version and tools.
- `.local/share/bin/manage-dotnet-tools` - Management script (deployed via stow).

## Usage

### Deploy the management script:
```bash
cd ~/darwin-config/stow
stow dotnet-tools
```

### Install all configured tools and SDK:
```bash
manage-dotnet-tools install
```

### Check status of configured tools:
```bash
manage-dotnet-tools status
```

### List all configured tools:
```bash
manage-dotnet-tools list
```

### Update all tools:
```bash
manage-dotnet-tools update
```

### Uninstall a specific tool:
```bash
manage-dotnet-tools uninstall
```

### Clean NuGet cache:
```bash
manage-dotnet-tools clean
```

### Add a new tool to configuration:
```bash
manage-dotnet-tools add
```

## Configuration Format

Edit `dotnet-tools.toml` to manage your .NET environment:

```toml
[sdk]
version = "9.0.301"
description = ".NET SDK for building applications"

[global_tools]
fsautocomplete = { version = "*", description = "F# Language Server Protocol implementation" }

[settings]
auto_update = true
use_exact = false
include_prerelease = false
install_timeout = 300
```

## Features

### SDK Management
- **Expected Version Check**: Ensures you are using the correct .NET SDK version.

### Global Tool Management
- **Declarative Configuration**: Define all your global tools in one file.
- **Version and Prerelease Control**: Install specific versions or include prereleases.

### System Integration
- **Stow Integration**: Easily deploys with your other managed scripts.
- **Version Control**: Configuration is tracked with your dotfiles.
- **Restoration**: Reinstall tools after system rebuilds.

## Benefits

1. **Version Control**: Your .NET environment preferences are tracked in git.
2. **Easy Restoration**: After system restore, one command reinstalls everything.
3. **Documentation**: Each tool has a description explaining its purpose.
4. **Integrated**: Works seamlessly with your existing setup.

## System Restoration Workflow

After a system wipe:
1. Install .NET SDK via system package manager or official installer.
2. Clone your darwin-config.
3. Run `cd ~/darwin-config/stow && stow dotnet-tools`.
4. Run `manage-dotnet-tools install`.

Your entire .NET development environment will be automatically restored!
