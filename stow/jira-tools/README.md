# JIRA Tools Package

This package provides utilities for managing JIRA API tokens securely using 1Password integration.

## Installation

This package is automatically available when darwin-config is installed. The tools are located in `~/.local/share/bin/`.

## Tools

### prepare-jira

Sets the `JIRA_API_TOKEN` environment variable in your current shell. Automatically detects your shell type and outputs the appropriate syntax.

#### Usage

```bash
# bash/zsh - evaluate the output
eval "$(prepare-jira)"
eval "$(prepare-jira personal)"  # personal profile

# fish - evaluate the output
eval (prepare-jira)
eval (prepare-jira personal)

# nushell - run the command directly (can't eval external output)
$env.JIRA_API_TOKEN = (get-jira-api-token personal)

# xonsh - evaluate the output
exec($(prepare-jira))
```

### jira-token-manager

A comprehensive utility for managing JIRA API tokens with 1Password integration.

#### Usage

```bash
jira-token-manager get [personal]     # Get JIRA API token
jira-token-manager set [personal]     # Set up JIRA API token interactively
jira-token-manager status             # Check token availability
jira-token-manager help               # Show help
```

#### Examples

```bash
# Get personal JIRA API token
jira-token-manager get personal

# Check status of JIRA tokens
jira-token-manager status

# Set up JIRA token interactively
jira-token-manager set personal
```

## Environment Variables

The following environment variables control the behavior:

- `JIRA_API_TOKEN`: Automatically set by the shell configurations when available

## 1Password Setup

### For Personal JIRA

1. Create an item named `jira-api-token` in your Personal vault
2. Add a field named `token` with your JIRA API token
3. Test: `jira-token-manager get personal`

## Shell Integration

The JIRA API token is available **on-demand** to avoid 1Password biometric prompts on every shell startup.

Use `prepare-jira` to set the token when needed:

| Shell | Command |
|-------|---------|
| bash/zsh | `eval "$(prepare-jira)"` |
| fish | `eval (prepare-jira)` |
| nushell | `$env.JIRA_API_TOKEN = (get-jira-api-token personal)` |
| xonsh | `exec($(prepare-jira))` |

## Troubleshooting

### Token Not Found

If you get "Not available" errors:

1. Check 1Password CLI: `op account list`
2. Check get-jira-api-token availability: `command -v get-jira-api-token`
3. Check 1Password setup: `jira-token-manager status`
4. Ensure darwin-config is properly built: `nb && ns`

### 1Password Not Signed In

Run `op signin` to authenticate with 1Password, then test again.
