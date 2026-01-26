# Secure Secrets Management Guide

This configuration provides multiple options for securely managing sensitive information like git credentials, API keys, and other secrets without hardcoding them in your configuration files.

## Overview

The secret management system supports two primary backends:

1. **1Password CLI** - Recommended if you have a 1Password subscription
2. **pass (password-store)** - Free, open-source alternative using GPG encryption

Both backends integrate seamlessly with:
- Git configurations
- Emacs auth-source system
- Custom scripts and automation

## Quick Setup

### Option 1: 1Password (Recommended)

```bash
# Set up 1Password credentials interactively
nix run .#setup-1password-secrets

# Or with command-line arguments
nix run .#setup-1password-secrets -- \
    --personal-name "Your Name" \
    --personal-email "you@personal.com"

# Update git configurations with secure credentials
update-git-secrets
```

### Option 2: pass (Free Alternative)

```bash
# Set up pass credentials interactively
nix run .#setup-pass-secrets

# Or with command-line arguments
nix run .#setup-pass-secrets -- \
    --personal-name "Your Name" \
    --personal-email "you@personal.com"

# Update git configurations with secure credentials
update-git-secrets
```

## Available Commands

| Command | Description |
|---------|-------------|
| `nix run .#setup-1password-secrets` | Set up 1Password for git credentials |
| `nix run .#setup-pass-secrets` | Set up pass for git credentials |
| `update-git-secrets` | Update git configs with secure credentials |
| `get-git-secret <type>` | Retrieve specific git credential |
| `setup-git-secrets` | Interactive setup guide |

## 1Password Setup Details

### Required 1Password Items

The system expects these items in your 1Password vaults:

**Personal Vault:**
- Item: `personal-git`
  - Field: `name` (Your full name for git commits)
  - Field: `email` (Your personal email address)

### Creating Items Manually

If you prefer to create the items manually in the 1Password app:

1. **Personal Git Credentials:**
   - Create a new "Secure Note" in your "Personal" vault
   - Title: `personal-git`
   - Add custom fields:
     - `name`: Your full name
     - `email`: Your personal email

## Pass Setup Details

### Directory Structure

Pass stores credentials in a hierarchical structure:

```
~/.password-store/
├── git/
│   ├── personal.gpg          # Dummy password (not used)
│   └── personal/
│       ├── name.gpg          # Personal git name
│       └── email.gpg         # Personal git email
```

### Manual Setup

If you prefer to set up pass manually:

```bash
# Initialize pass with your GPG key
pass init <your-gpg-key-id>

# Add personal credentials
pass insert git/personal/name
pass insert git/personal/email
```

## How It Works

### Git Configuration

The system creates dynamic git configuration files:

- `~/.config/git/config-personal` - For personal repositories

These files are automatically generated based on your secure credentials and included conditionally by your main git config based on the repository location.

### Automatic Updates

A launchd agent automatically refreshes your git configurations:
- Runs on system login
- Runs every 6 hours to refresh credentials
- Ensures your git configs always have current credentials

### Fallback Behavior

If credentials cannot be retrieved from secure storage, the system falls back to:
- Personal email: `${USER}@users.noreply.github.com`
- Name: `${USER}`

## Integration with Emacs

### Auth-Source Configuration

Emacs is configured to use multiple credential sources:

1. `~/.authinfo.gpg` (GPG-encrypted)
2. `~/.authinfo` (plain text, not recommended)
3. `~/.netrc` (legacy format)

### Enhanced Functions

The enhanced auth configuration provides:

- `my/get-git-credentials` - Get git credentials based on current directory
- `my/get-api-key` - Retrieve API keys for services
- `my/get-database-url` - Get database connection URLs
- `my/refresh-credentials` - Clear credential cache

### Security Features

- **Automatic cache expiry** (1 hour)
- **Hardcoded credential detection** - Warns about potential security issues
- **Magit integration** - Sets secure credentials for git operations

## Troubleshooting

### 1Password Issues

```bash
# Check if 1Password CLI is working
op account list

# Sign in if needed
op signin

# Test credential retrieval
op item get personal-git --fields name
```

### Pass Issues

```bash
# Check if pass is working
pass show

# List available credentials
pass show git/

# Test retrieval
pass show git/personal/name
```

### Git Configuration Issues

```bash
# Check current git config
git config --list | grep user

# Manually update git secrets
update-git-secrets

# Test secret retrieval
get-git-secret git-email-personal
```

## Security Best Practices

### GPG Key Management

For pass users:
- Use a strong passphrase for your GPG key
- Back up your GPG key securely
- Consider using a hardware security key

### 1Password Security

- Use a strong master password
- Enable two-factor authentication

### General Security

- **Never commit secrets** to git repositories
- **Use secure communication** for sharing credentials
- **Regularly rotate** API keys and passwords
- **Monitor** for hardcoded credentials in your configurations

## Migration Guide

### From Hardcoded Credentials

If you're migrating from hardcoded credentials:

1. **Audit your configuration:**
   ```bash
   # Search for patterns that might be credentials
   grep -r "@.*\.com" ~/darwin-config/
   ```

2. **Move credentials to secure storage:**
   ```bash
   # Use either 1Password or pass setup scripts
   nix run .#setup-1password-secrets
   # or
   nix run .#setup-pass-secrets
   ```

3. **Update configurations:**
   ```bash
   update-git-secrets
   ```

4. **Remove hardcoded values** from your configuration files

### From Other Secret Managers

If you're using other secret management tools:
- Export your credentials
- Import them into either 1Password or pass
- Follow the setup guide for your chosen backend

## Advanced Usage

### Custom Secret Types

You can extend the system to handle other types of secrets by modifying `modules/secure-credentials.nix`:

```nix
# Add new secret types to the getCredentialScript function
case "${secretType}" in
    "api-key-github")
        get_from_1password "github-api" "token" "Development"
        ;;
    "database-password")
        get_from_pass "databases/production" "password"
        ;;
esac
```

### Environment-Specific Credentials

For different environments (staging, production, etc.):

```bash
# 1Password approach - use different vaults
op item get api-keys --vault="Staging"
op item get api-keys --vault="Production"

# Pass approach - use directory structure
pass show environments/staging/api-key
pass show environments/production/api-key
```

### Automation Scripts

You can create scripts that automatically retrieve and use credentials:

```bash
#!/usr/bin/env bash
API_KEY=$(get-git-secret api-key-service)
curl -H "Authorization: Bearer $API_KEY" https://api.example.com/
```

## Related Documentation

- [Multi-User Setup Guide](MULTI-USER-SETUP.md) - How to configure for different users
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [Pass Documentation](https://www.passwordstore.org/)
- [Auth-Source Manual](https://www.gnu.org/software/emacs/manual/html_mono/auth.html)

## Contributing

If you enhance the secret management system:
- Test with both 1Password and pass backends
- Ensure fallback behavior functions correctly
- Document any new secret types or integration points
- Consider security implications of changes

---

**Security Note**: This system is designed to keep secrets out of your configuration files while maintaining usability. Always follow security best practices and regularly audit your credential management setup.
