# Node.js Tools Management

This stow package provides version-controlled management of Node.js tools and global packages. It integrates with Volta for Node.js version management and supports npm, yarn, and pnpm package managers.

## How It Works

1. **Configuration Tracking**: `nodejs-tools.toml` tracks your desired Node.js toolchain and global packages
2. **Management Script**: `manage-nodejs-tools` provides commands to install, update, and manage tools
3. **Version Control**: Your Node.js tool configuration is tracked in git with your darwin-config
4. **System Restoration**: After a system wipe, easily reinstall your entire Node.js environment

## Files

- `nodejs-tools.toml` - Configuration file listing desired toolchain and packages
- `.local/share/bin/manage-nodejs-tools` - Management script (deployed via stow)

## Usage

### Deploy the management script:
```bash
cd ~/darwin-config/stow
stow nodejs-tools
```

### Install all configured packages and toolchain:
```bash
manage-nodejs-tools install
```

### Check status of configured packages:
```bash
manage-nodejs-tools status
```

### List configured packages:
```bash
manage-nodejs-tools list
```

### Update all packages:
```bash
manage-nodejs-tools update
```

### Clean package manager cache:
```bash
manage-nodejs-tools clean
```

### Add a new package to configuration:
```bash
manage-nodejs-tools add
```

## Configuration Format

Edit `nodejs-tools.toml` to manage your Node.js environment:

```toml
[toolchain]
# Node.js version (managed by Volta)
node = { version = "22.16.0", description = "Node.js runtime" }

# Optional: Additional package managers
yarn = { version = "latest", description = "Fast package manager" }
pnpm = { version = "latest", description = "Efficient package manager" }

[global_packages]
# Development tools
typescript = { version = "*", description = "TypeScript compiler" }
tsx = { version = "*", description = "TypeScript execution engine" }
eslint = { version = "*", description = "JavaScript/TypeScript linter" }
prettier = { version = "*", description = "Code formatter" }

# Build tools
vite = { version = "*", description = "Fast build tool" }
webpack-cli = { version = "*", description = "Webpack command line interface" }

# Utilities
nodemon = { version = "*", description = "File watcher for development" }
pm2 = { version = "*", description = "Process manager" }
serve = { version = "*", description = "Static file server" }

[settings]
package_manager = "npm"  # Options: npm, yarn, pnpm
auto_update = true
use_exact = false
use_volta = true
```

## Features

### Toolchain Management
- **Volta Integration**: Automatically manages Node.js versions via Volta
- **Package Manager Support**: Works with npm, yarn, and pnpm
- **Version Pinning**: Pin specific versions or use latest

### Global Package Management
- **Declarative Configuration**: Define all your global packages in one file
- **Cross-Platform**: Works across different systems
- **Flexible Versioning**: Support for semantic versioning or exact versions

### System Integration
- **Stow Integration**: Seamlessly deploys with your other managed scripts
- **Version Control**: Configuration tracked with your dotfiles
- **Restoration**: Easy recovery after system rebuilds

## Benefits

1. **Version Control**: Your Node.js environment preferences are tracked in git
2. **Easy Restoration**: After system restore, one command reinstalls everything
3. **Documentation**: Each tool has a description explaining its purpose
4. **Flexibility**: Supports multiple package managers and version strategies
5. **Integration**: Works seamlessly with Volta and your existing setup

## System Restoration Workflow

After a system wipe:
1. Install Volta (via homebrew/nix)
2. Clone your darwin-config
3. Run `cd ~/darwin-config/stow && stow nodejs-tools`
4. Run `manage-nodejs-tools install`

Your entire Node.js development environment will be automatically restored!

## Notes

- **Node Modules**: This system intentionally does NOT track node_modules or other temporary files
- **Global Focus**: Manages only globally installed packages, not project dependencies
- **Volta First**: Designed to work with Volta for Node.js version management
- **Gitignore Respect**: Follows your existing gitignore patterns to avoid tracking temporary files
