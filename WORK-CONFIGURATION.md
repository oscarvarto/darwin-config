# Work Configuration Guide

This repository has been updated to remove hardcoded company-specific information and replace it with a configurable work profile system.

## Overview

Previously, the repository contained hardcoded references to specific company information (database names, directory patterns, etc.). This has been replaced with a configurable system that allows each host to specify its work-specific settings.

## Configuration Structure

Work-specific settings are configured in `flake.nix` under each host's `hostSettings.workConfig` section:

```nix
hostSettings = {
  enablePersonalConfig = false;  # Set to false for work machines
  workProfile = true;           # Enable work-specific features
  
  # Work-specific configuration
  workConfig = {
    companyName = "YourCompany";           # Your company name
    gitWorkDirPattern = "~/work/**";       # Git directory pattern for work repos
    databaseName = "your_db";              # Work database name
    databaseHost = "localhost";            # Database host
    databasePort = "3306";                 # Database port
    opVaultName = "Work";                  # 1Password vault name
    opItemName = "YourCompany";            # 1Password item name
  };
};
```

## Environment Variables

These configuration values are automatically converted to environment variables that can be used by scripts and applications:

- `WORK_COMPANY_NAME` - Company name
- `WORK_GIT_DIR_PATTERN` - Git directory pattern (e.g., "~/work/**")
- `WORK_DB_NAME` - Database name
- `WORK_DB_HOST` - Database host
- `WORK_DB_PORT` - Database port  
- `WORK_OP_VAULT` - 1Password vault name
- `WORK_OP_ITEM` - 1Password item name

## Files Updated

The following files have been updated to use configurable settings instead of hardcoded values:

### 1. Git Configuration Scripts
- **File**: `modules/scripts/nu/update-work-git-config.nu`
- **Change**: Uses `WORK_COMPANY_NAME`, `WORK_OP_VAULT`, `WORK_OP_ITEM`, and `WORK_GIT_DIR_PATTERN`

### 2. Git Directory Patterns
- **File**: `modules/home-manager.nix`
- **Change**: Git `includeIf` configuration now uses the configurable work directory pattern

## Setting Up for Your Work Environment

### 1. Update flake.nix

Edit your host configuration in `flake.nix`:

```nix
your-work-machine = {
  user = "your-username";
  system = "aarch64-darwin";
  defaultShell = "zsh";
  hostSettings = {
    enablePersonalConfig = false;
    workProfile = true;
    workConfig = {
      companyName = "ACME Corp";              # Your actual company name
      gitWorkDirPattern = "~/acme/**";        # Your work git directory pattern
      databaseName = "acme_production";       # Your work database name
      databaseHost = "db.acme.com";           # Your database host
      databasePort = "5432";                  # Your database port
      opVaultName = "Work";                   # Your 1Password vault
      opItemName = "ACME Corp";               # Your 1Password item
    };
  };
};
```

### 2. Set Up 1Password Integration

1. Create a 1Password item in your Work vault
2. Title the item with your company name (matching `opItemName`)
3. Add an "email" field with your work email address
4. Ensure you're signed in to 1Password CLI: `op signin`

### 3. Rebuild Configuration

```bash
# Using aliases
ns  # Build and switch

# Or using nix run
nix run .#build-switch
```

## Verification

After rebuilding, you can verify the configuration:

1. **Check environment variables**:
   ```bash
   echo $WORK_COMPANY_NAME
   echo $WORK_GIT_DIR_PATTERN
   ```

2. **Test git configuration**:
   ```bash
   # Navigate to your work directory
   cd ~/your-work-dir/some-repo
   git config --get user.email  # Should show your work email
   ```

3. **Test work git config script**:
   ```bash
   ~/darwin-config/modules/scripts/nu/update-work-git-config.nu
   ```

## Migration from Previous Setup

If you were using the previous setup with hardcoded "iRhythm" references:

1. Update your `workConfig` in `flake.nix` with your actual company details
2. Update your 1Password items to match the new naming scheme
3. Move your work repositories to match your new `gitWorkDirPattern`
4. Rebuild your configuration with `ns` or `nix run .#build-switch`

## Security Benefits

This new approach provides several security benefits:

1. **No hardcoded secrets**: All sensitive information is retrieved from secure credential stores
2. **Company-agnostic**: The repository can be shared without exposing company-specific information
3. **Flexible configuration**: Easy to adapt for different work environments
4. **Separation of concerns**: Work and personal configurations are clearly separated

## Troubleshooting

### 1Password Issues
- Ensure you're signed in: `op signin`
- Verify your vault and item names match your configuration
- Check that the "email" field exists in your 1Password item

### Git Configuration Issues
- Check that your work directory pattern is correct
- Ensure the work git config file exists: `~/.config/git/config-work`
- Test with: `git config --get user.email` in a work repository

### Environment Variable Issues
- Restart your shell or reload your configuration
- Check that the variables are set: `env | grep WORK_`
