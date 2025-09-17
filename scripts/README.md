# Darwin Config Scripts

This directory contains helper scripts to automate multi-user and multi-host configuration management.

## Scripts

### `configure-user.sh`

Configures and validates the darwin-config for a specific user and hostname combination.

**Usage:**
```bash
# Run via Nix app (recommended)
nix run .#configure-user -- [OPTIONS]

# Or directly (uses system zsh)
./scripts/configure-user.sh [OPTIONS]
```

**Options:**
- `-u, --user USER`: Target username (defaults to current $USER)
- `--hostname HOST`: Target hostname (defaults to current hostname)
- `-w, --work-profile`: Enable work profile configuration
- `-p, --personal-config`: Enable personal configuration  
- `-d, --dry-run`: Show what would be changed without making changes
- `-h, --help`: Show help message

**Examples:**
```bash
# Check current configuration
nix run .#configure-user -- --dry-run

# Configure for a specific user/hostname
nix run .#configure-user -- --user alice --hostname alice-macbook

# Preview work profile setup
nix run .#configure-user -- --user bob --hostname work-laptop --work-profile --dry-run
```

**What it does:**
- Validates that the hostname configuration exists in flake.nix
- Checks for potential issues (missing user directories, etc.)
- Tests builds for the target configuration
- Provides guidance on next steps

### `add-host.sh`

Automatically adds a new host configuration to flake.nix.

**Usage:**
```bash
# Run via Nix app (recommended)
nix run .#add-host -- --hostname HOST --user USER [OPTIONS]

# Or directly (uses system zsh)
./scripts/add-host.sh --hostname HOST --user USER [OPTIONS]
```

**Required:**
- `--hostname HOST`: Target hostname
- `-u, --user USER`: Target username

**Options:**
- `-s, --system ARCH`: System architecture (default: aarch64-darwin)
- `-w, --work-profile`: Enable work profile configuration
- `-p, --personal-config`: Enable personal configuration
- `-d, --dry-run`: Show what would be changed without making changes
- `-h, --help`: Show help message

**Examples:**
```bash
# Add a new personal machine
nix run .#add-host -- --hostname alice-macbook --user alice --personal-config

# Add a work machine
nix run .#add-host -- --hostname work-laptop --user bob --work-profile

# Preview changes without applying
nix run .#add-host -- --hostname test --user test --dry-run
```

**What it does:**
- Adds the host configuration to `hostConfigs` in flake.nix
- Tests the build to ensure the new configuration works
- Provides instructions for next steps
- Automatically reverts changes if the build fails

## Architecture Support

Supported:
- `aarch64-darwin`: Apple Silicon Macs (M1, M2, M3, etc.)

## Configuration Flags

### `enablePersonalConfig`
- `true`: Uses personal name/email from userConfig
- `false`: Uses generic user information

### `workProfile`  
- `true`: Sets up work-specific directory structures and git configs
- `false`: Uses personal/development directory structure

## Integration with Nix Apps

These scripts are automatically available as Nix apps through the flake:

```bash
nix run .#add-host
nix run .#configure-user
```

This ensures they run reliably on any macOS system.

## Requirements

- **Zsh**: Scripts are written in Zsh (available on all macOS systems by default)
- **Nix with flakes**: Required for building and testing configurations
- **Git**: Repository must be a git repository for flake to work properly

## Error Handling

Both scripts include comprehensive error handling:
- Validate required parameters
- Check for existing configurations
- Test builds before committing changes
- Provide clear error messages and guidance
- Automatic rollback on build failures (add-host)
- Colored output for better visibility

## Development

To modify these scripts:

1. Edit the `.sh` files directly
2. Test with `--dry-run` flag first
3. Scripts are automatically included in the flake when git-tracked
4. Changes take effect immediately when using `nix run .#script-name`
5. Scripts use standard zsh/bash features for maximum compatibility
