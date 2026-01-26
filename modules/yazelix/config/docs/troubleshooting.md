# Troubleshooting

## Quick Diagnosis

**🔍 Start here:** Run the automated health check to identify common issues:

```bash
yzx doctor                    # Check for problems
yzx doctor --verbose          # Detailed information  
yzx doctor --fix              # Auto-fix safe issues
```

**What it checks:**
- **Environment variables** - EDITOR and other critical settings
- **Configuration health** - yazelix.toml validation and shell integration
- **System status** - Log file sizes, file permissions, git repository state

**Auto-fix capabilities:**
- Clean oversized log files
- Create missing configuration files

## Configuration File Migration

**Yazelix now uses `yazelix.toml` instead of the old `yazelix.nix`.**

If you have an older Yazelix setup:
- Configuration is now in `~/.config/yazelix/yazelix.toml` (not `yazelix.nix`)
- The default template is `yazelix_default.toml`

**Migration steps:**
1. Your `yazelix.toml` will be auto-created from `yazelix_default.toml` on yazelix startup if not found
2. Copy any custom settings from your old `yazelix.nix` to the new `yazelix.toml` format

## First Run: Zellij Plugin Permissions (is the top bar looking funny/weird/broken?)

When you first run yazelix, **zjstatus requires you to give it permission:**

Zellij requires plugins to request permissions for different actions and information. These permissions must be granted by you before you start zjstatus. Permissions can be granted by navigating to the zjstatus pane either by keyboard shortcuts (alt h/j/k/l) or clicking on the (top) pane. Then simply type the letter `y` to approve permissions. This process must be repeated on zjstatus updates, since the file changes.

See the [zjstatus permissions documentation](https://github.com/dj95/zjstatus/wiki/2-%E2%80%90-Permissions) for more details.

## Quick Fixes

### Reset Configuration
```bash
rm ~/.config/yazelix/yazelix.toml
exit         # Exit current session
yzx launch   # Start fresh in new window - regenerates defaults
```

### Restart Fresh
```bash
exit        # Exit current session  
yzx launch  # Start new session in new window
```

## Editor Issues

### File Opening Broken
```bash
echo $EDITOR                    # Should show path
tail ~/.config/yazelix/logs/open_editor.log
```

### Runtime Errors
```bash
echo $EDITOR
```

## Getting Help

1. Check logs: `~/.config/yazelix/logs/`
2. Test with defaults: delete `yazelix.toml`
3. Report issues
