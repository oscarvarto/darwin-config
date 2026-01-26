# Darwin Config Scripts

This directory contains helper scripts for the darwin-config setup and maintenance.

> **Prerequisite**
>
> Run `nix run .#record-config-path` after cloning (and again whenever you relocate the repository), then restart your shell. Scripts in this directory expect the `DARWIN_CONFIG_PATH` environment variable to point at your darwin-config checkout.

## Available Scripts

### Secrets Management

- `setup-1password-secrets.sh` - Set up 1Password for secure git credentials
- `setup-pass-secrets.sh` - Set up pass (password-store) for secure git credentials

### Utility Scripts

- `record-darwin-config-path.sh` - Persist the repository path for other scripts
- `sanitize-sensitive-data.sh` - Sanitize repository of sensitive information

## Integration with Nix Apps

These scripts are available as Nix apps through the flake:

```bash
nix run .#record-config-path
nix run .#setup-1password-secrets
nix run .#setup-pass-secrets
nix run .#sanitize-repo
```

## Requirements

- **Zsh/Bash**: Scripts use standard shell features
- **Nix with flakes**: Required for building and testing configurations
- **Git**: Repository must be a git repository for flake to work properly
