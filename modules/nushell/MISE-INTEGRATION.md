# Mise Integration for Nushell

This repository implements manual mise (formerly rtx) integration for Nushell, providing automatic environment management for development tools.

## Overview

Due to incompatibilities between home-manager's auto-generated mise configuration and current Nushell versions, we use a custom `mise.nu` module that provides full mise functionality with proper Nushell syntax.

## Features

- ✅ Automatic initialization on Nushell startup
- ✅ Directory-based tool activation (via `mise.toml` files)
- ✅ Hooks for PWD changes to activate tools automatically
- ✅ Full mise command support via module interface
- ✅ Proper environment variable management (PATH, JAVA_HOME, etc.)

## How It Works

1. **Module Loading**: When Nushell starts, it loads `~/.config/nushell/mise.nu`
2. **Auto-Initialization**: The `export-env` block runs `mise hook-env` to set up initial environment
3. **Hook Registration**: Hooks are registered for `pre_prompt` and `PWD` changes
4. **Directory Activation**: When you `cd` into a directory with `mise.toml`, tools are automatically activated

## Usage

### Basic Commands

Once Nushell is started with mise integration, you can use mise commands directly:

```nushell
# Check mise version
mise version

# List all installed tools
mise list

# Show currently active tools
mise current

# Install a tool
mise install node@20

# Use a specific tool version
mise use java@corretto-21
```

### Example: Directory-Based Activation

Create a `mise.toml` in your project:

```toml
[tools]
node = "20"
java = "corretto-21"
python = "3.11"
```

When you `cd` into this directory:
```nushell
cd ~/my-project
# mise automatically activates node@20, java@corretto-21, python@3.11
# Environment variables like JAVA_HOME are set automatically

which java  # Points to mise-managed Java 21
$env.JAVA_HOME  # Set to the corretto-21 installation path
```

## Implementation Details

### File Structure

```
modules/nushell/
├── config.nu          # Main config, sources mise.nu
├── mise.nu            # Mise integration module
├── default.nix        # Deploys mise.nu via Nix
└── MISE-INTEGRATION.md  # This file
```

### Module Architecture

The `mise.nu` module exports:

- **`main`**: Main command handler (allows `mise <command>` syntax)
- **`export-env`**: Initializes mise and sets up hooks automatically
- **Internal functions**:
  - `parse vars`: Parses mise's CSV output
  - `update-env`: Applies environment changes
  - `add-hook`: Registers hooks in Nushell config
  - `mise_hook`: Triggered on directory changes

### Why Manual Integration?

The home-manager mise module generates Nushell configuration with syntax patterns that are incompatible with recent Nushell versions:

```nix
# In modules/home-manager.nix
mise = {
  enable = true;
  enableNushellIntegration = false;  # Disabled due to syntax incompatibility
};
```

Our manual approach:
1. Uses `mise activate nu` as a base template
2. Adapts syntax for current Nushell versions
3. Wraps everything in a proper Nushell module
4. Auto-initializes via `export-env` block

## Testing

To verify mise integration is working:

```nushell
# Check mise is loaded
$env.MISE_SHELL  # Should output "nu"

# Test mise commands
mise version
mise list

# Test directory activation
cd ~/darwin-config
mise current  # Should show active tools from mise.toml
```

## Maintenance

### Updating Mise Configuration

If mise releases breaking changes to its Nushell integration:

1. Generate new activation script:
   ```bash
   mise activate nu > /tmp/mise-new.nu
   ```

2. Compare with current `modules/nushell/mise.nu`:
   ```bash
   diff /tmp/mise-new.nu modules/nushell/mise.nu
   ```

3. Update `mise.nu` with any necessary changes

4. Test thoroughly before committing

### Re-enabling Home-Manager Integration

If home-manager's mise module is updated to support newer Nushell:

1. Change in `modules/home-manager.nix`:
   ```nix
   enableNushellIntegration = true;
   ```

2. Remove manual integration from `config.nu`:
   ```nushell
   # Remove: use ~/.config/nushell/mise.nu
   ```

3. Remove deployment in `modules/nushell/default.nix`:
   ```nix
   # Remove: file.".config/nushell/mise.nu".source = ./mise.nu;
   ```

4. Keep `mise.nu` as a backup/reference

## Troubleshooting

### Tools Not Activating

**Problem**: Tools don't activate when entering a directory with `mise.toml`

**Solution**:
```nushell
# Manually trigger mise hook
^mise hook-env -s nu | parse vars | update-env

# Check if hooks are registered
$env.config.hooks.env_change.PWD
```

### Environment Variables Not Set

**Problem**: `$env.JAVA_HOME` or similar variables not set

**Solution**:
```nushell
# Check mise status
mise doctor

# Verify tool is installed
mise list

# Manually activate tools in current directory
cd .  # Triggers PWD hook
```

### Module Loading Errors

**Problem**: Errors when Nushell starts

**Solution**:
```nushell
# Test mise.nu in isolation
nu --config /dev/null --env-config /dev/null -c "use ~/.config/nushell/mise.nu; mise version"

# Check Nushell version compatibility
version
```

## References

- [mise Documentation](https://mise.jdx.dev/)
- [mise Nushell Integration](https://mise.jdx.dev/ide-integration.html#nushell)
- [Nushell Modules](https://www.nushell.sh/book/modules.html)
- [Nushell Hooks](https://www.nushell.sh/book/hooks.html)
