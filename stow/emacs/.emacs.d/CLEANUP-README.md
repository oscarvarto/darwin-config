# Emacs Clean Reinstall Guide

## Quick Start

```bash
# Run the cleanup script
~/.emacs.d/cleanup-and-reinstall.sh

# Or with full path
bash ~/.emacs.d/cleanup-and-reinstall.sh
```

## What the Script Does

### Deletes (forces fresh install):
- ✗ `~/.emacs.d/elpaca/` - All packages
- ✗ `~/.emacs.d/.lsp-session-*` - LSP session cache
- ✗ `~/.emacs.d/workspace/` - LSP workspace
- ✗ `~/.emacs.d/.cache/` - General cache
- ✗ `~/.emacs.d/eln-cache/` - Native compilation cache
- ✗ `~/.emacs.d/.lsp-mode-*` - Rebuild markers

### Preserves (your configuration):
- ✓ `~/.emacs.d/init.el` - Main config
- ✓ `~/.emacs.d/my/*.el` - All your custom configs

### Creates backups:
- 📦 `~/.emacs.d/my.backup.TIMESTAMP/`
- 📦 `~/.emacs.d/init.el.backup.TIMESTAMP`

## After Running the Script

### 1. Start Emacs
```bash
emacs
```

### 2. Wait for Package Installation (2-5 minutes)
- Elpaca will automatically download and compile all packages
- Watch the `*Messages*` buffer for progress
- Look for: `"Elpaca processed N packages"`

**Important**: During this phase:
- ✅ `lsp-use-plists=t` is set BEFORE lsp-mode loads
- ✅ lsp-booster advice is installed BEFORE lsp-mode compiles
- ✅ Everything compiles correctly from the start

### 3. Restart Emacs (Important!)
After all packages are installed, **restart Emacs** to ensure everything is properly loaded.

### 4. Test with Java File
Open a Java file and check `*Messages*` buffer:

**Should See** ✅:
- `"Using emacs-lsp-booster for..."`
- `"LSP :: Connected to [jdtls:...]"`

**Should NOT See** ❌:
- `"Error processing message (wrong-type-argument hash-table-p...)"`
- `"Yasnippet is not installed..."`

## Manual Cleanup (Alternative)

If you prefer to run commands manually:

```bash
# 1. Create backups
cp -r ~/.emacs.d/my ~/.emacs.d/my.backup.$(date +%Y%m%d-%H%M%S)
cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup.$(date +%Y%m%d-%H%M%S)

# 2. Delete packages and caches
rm -rf ~/.emacs.d/elpaca/
rm -rf ~/.emacs.d/.lsp-session-*
rm -rf ~/.emacs.d/workspace/
rm -rf ~/.emacs.d/.cache/
rm -rf ~/.emacs.d/eln-cache/
rm -f ~/.emacs.d/.lsp-mode-*

# 3. Start Emacs
emacs
```

## Troubleshooting

### If you still see errors after cleanup:

1. **Verify lsp-booster is installed:**
   ```bash
   which emacs-lsp-booster
   # Should show: /path/to/emacs-lsp-booster

   # If not found, install it:
   cargo install emacs-lsp-booster
   ```

2. **Check my-lsp.el has correct order:**
   ```bash
   head -60 ~/.emacs.d/my/my-lsp.el | grep -E "lsp-use-plists|advice-add|use-package"
   ```

   Should show:
   - Line ~10: `(setq lsp-use-plists t)`
   - Line ~30: `(advice-add 'json-parse-buffer...)`
   - Line ~52: `(advice-add 'lsp-resolve-final-command...)`
   - Line ~55: `(use-package lsp-mode...)`

3. **Verify no Emacs processes are running before cleanup:**
   ```bash
   pgrep -a emacs
   # Should show nothing. If it does, kill them:
   pkill -9 emacs
   ```

4. **Check elpaca actually deleted:**
   ```bash
   ls ~/.emacs.d/elpaca/
   # Should show: "No such file or directory"
   ```

## Why This Works

The key issue was that lsp-mode advice was being installed **after** lsp-mode compiled, causing a hash-table vs plist mismatch.

**Fixed by**:
1. Setting `lsp-use-plists=t` at the TOP of my-lsp.el
2. Installing advice functions BEFORE `use-package lsp-mode`
3. Forcing a clean recompile of all packages

This ensures lsp-mode compiles with plist support from the start, and the advice is available during compilation.

## Configuration Files Order

The configuration loads in this order:

```
init.el
  └─> my-lsp.el
       ├─> (setq lsp-use-plists t)        # First
       ├─> (advice-add ...)               # Second
       └─> (use-package lsp-mode ...)     # Third (triggers compilation)
```

## Restore from Backup

If something goes wrong:

```bash
# Find your backup
ls -la ~/.emacs.d/*.backup*

# Restore configuration
rm -rf ~/.emacs.d/my
cp -r ~/.emacs.d/my.backup.TIMESTAMP ~/.emacs.d/my

cp ~/.emacs.d/init.el.backup.TIMESTAMP ~/.emacs.d/init.el
```
