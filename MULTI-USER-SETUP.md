# Multi-User and Multi-Host Setup Guide

This darwin-config has been designed to be easily reusable across different users and hostnames. Here's how to adapt it for your needs.

## Quick Setup for New Users

### 1. Fork/Clone the Repository

```bash
git clone https://github.com/your-username/darwin-config.git ~/darwin-config
cd ~/darwin-config
```

### 2. Update Host Configuration

Edit `flake.nix` and add your host to the `hostConfigs` section:

```nix
hostConfigs = {
  # Add your host here
  your-hostname = {
    user = "yourusername";
    system = "aarch64-darwin";
    hostSettings = {
      enablePersonalConfig = true;
    };
  };
};
```

### 3. Update Personal Information (Optional)

If you want to customize personal information, modify the `userConfig` in `modules/home-manager.nix`:

```nix
userConfig = {
  name = if hostSettings.enablePersonalConfig then "Your Full Name" else user;
  email = if hostSettings.enablePersonalConfig then "your.email@domain.com" else "${user}@example.com";
};
```

### 4. Update Secrets Repository (If Using)

In `flake.nix`, update the secrets URL to point to your own secrets repository:

```nix
secrets = {
  url = "git+ssh://git@github.com/yourusername/nix-secrets.git";
  flake = false;
};
```

### 5. Build and Switch

```bash
# Build the configuration for your hostname
nix run .#build-switch --extra-experimental-features "nix-command flakes"

# Or use the hostname-specific build
darwin-rebuild switch --flake .#your-hostname
```

## Automated Setup Tools

This configuration includes helpful Nix apps to automate the setup process:

### Adding New Hosts

Use the `add-host` app to automatically add new host configurations:

```bash
# Add a new personal machine
nix run .#add-host -- --hostname alice-macbook --user alice --personal-config

# Add another machine
nix run .#add-host -- --hostname secondary-mac --user alice --personal-config

# Preview changes without applying
nix run .#add-host -- --hostname test --user test --dry-run
```

This tool will:
- Add the host configuration to `flake.nix`
- Test the build to ensure it works
- Provide next steps for setup

### Configuring for Different Users

Use the `configure-user` app to check and configure for different users/hostnames:

```bash
# Check current configuration
nix run .#configure-user -- --dry-run

# Configure for a specific user/hostname
nix run .#configure-user -- --user alice --hostname alice-macbook

# Preview what would change for a different setup
nix run .#configure-user -- --user bob --hostname secondary-mac --dry-run
```

This tool will:
- Verify the hostname exists in the configuration
- Check for potential issues (missing user directories, etc.)
- Test builds for the target configuration
- Provide guidance on next steps

## Host Configuration Options

### System Architecture
- `aarch64-darwin` - Apple Silicon Macs (M1, M2, M3, etc.)

### Host Settings

- `enablePersonalConfig` - When `true`, uses personal name/email from userConfig

## Directory Structure Assumptions

The configuration assumes the following directory structure:

```
~/darwin-config/           # This repository
~/dev/                     # Development projects
~/.ssh/                    # SSH keys
~/.config/                 # Application configs
~/.local/share/bin/        # User scripts (managed by stow)
```

## Customizing for Different Machines

### Primary Machine

```nix
hostSettings = {
  enablePersonalConfig = true;
};
```

### Secondary/Shared Machine

```nix
hostSettings = {
  enablePersonalConfig = false;  # Uses generic user info
};
```

### Git Configuration

The git configuration automatically adapts based on the host settings:

- Git uses conditional includes for different directories
- Personal config is used by default

Create these files in your home directory:
- `~/.config/git/config-personal` - Personal git config (personal email, etc.)

### Stow Scripts

The stow-managed scripts under `./stow/` automatically use the correct user paths. No manual changes needed for different users.

## Adding New Hosts

To add a new host:

1. Add the host configuration to `flake.nix`
2. Optionally create host-specific modules in `hosts/[hostname]/`
3. Build with the new hostname: `darwin-rebuild switch --flake .#hostname`

## Environment Variables and Paths

All user-specific paths are dynamically generated:
- `/Users/${user}/*` - User home directory paths
- Shell configurations automatically use the correct user
- Homebrew, Nix profiles, and other tools work seamlessly

## SSH and Secrets

- SSH configurations in `modules/secrets.nix` use dynamic user paths
- Age identity paths automatically adjust: `/Users/${user}/.ssh/id_ed25519`
- Update your secrets repository URL in `flake.nix`

## Shell Aliases

The `nb` and `ns` aliases automatically work from any directory for any user:
- `nb` - Build nix configuration
- `ns` - Build and switch nix configuration

These are defined in `modules/shell-config.nix` and use `$HOME/darwin-config`.

## Troubleshooting

### Build Errors
- Ensure your hostname matches what's defined in `hostConfigs`
- Check that all user-specific paths are accessible
- Verify SSH keys exist if using secrets

### Permission Issues
- Make sure the user has admin privileges for system changes
- Verify SSH keys have correct permissions (600)

### Path Issues
- All paths are now relative to the user, so they should work automatically
- If you see hardcoded paths, they should be reported as bugs

## Advanced Customization

### Custom Host-Specific Modules

You can create host-specific modules:

```nix
# In hosts/your-hostname/default.nix
{ config, pkgs, ... }:
{
  # Host-specific configuration here
}
```

Then import it in your system configuration.

### Per-Host Package Lists

You can conditionally include packages based on host settings:

```nix
home.packages = (pkgs.callPackage ./packages.nix {}) ++
  lib.optionals hostSettings.enablePersonalConfig [
    pkgs.additional-packages
  ];
```

This setup provides a flexible, reusable configuration that can be easily adapted for different users and machines.
