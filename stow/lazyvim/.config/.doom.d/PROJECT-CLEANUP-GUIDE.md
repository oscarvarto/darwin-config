# Project Cleanup Protection for Doom Emacs

## What This Solves

When you delete a project folder, Emacs complains about missing files/projects because:
1. **`recentf`** caches recently opened files
2. **`projectile`** caches known projects  
3. **`treemacs`** persists workspace/project data
4. **`savehist`** stores command history with project paths

## Automatic Protection (Already Configured)

### ✅ Auto-Cleanup Features
- **On startup**: Cleans invalid projects after 5 seconds
- **Every 10 minutes**: Removes non-existent files from recentf
- **Every 20 minutes**: Cleans treemacs workspaces
- **Every 30 minutes**: Cleans projectile known projects
- **When switching projects**: Auto-cleans projectile cache
- **When killing buffers**: Cleans up if from deleted projects

### ✅ Manual Commands Available
- **`SPC p c`** - Clean up invalid projects manually
- **`M-x my/clean-invalid-projects`** - Same as above
- **`M-x my/emergency-project-cleanup`** - Nuclear option (backs up first)

## Cache File Locations

All cache files are in `~/.emacs.d/.local/cache/`:
- **`recentf`** - Recent files history
- **`treemacs-persist`** - Treemacs workspace data  
- **`savehist`** - Command history
- **`projectile/`** - Projectile project cache

## If You Still Have Issues

### Quick Fix
```elisp
M-x my/clean-invalid-projects
```

### Nuclear Option
```elisp
M-x my/emergency-project-cleanup
```
This will:
1. Backup all cache files to `~/.emacs.d/.local/cache/backup/`
2. Clean up invalid references
3. Reset projectile cache
4. Offer to restart Emacs

### Manual Cache Cleanup
If needed, you can manually delete cache files:
```bash
# Remove specific caches
rm ~/.emacs.d/.local/cache/recentf
rm ~/.emacs.d/.local/cache/treemacs-persist
rm -rf ~/.emacs.d/.local/cache/projectile/

# Then restart Emacs
```

## Prevention Tips

1. **Don't delete projects while Emacs is open** - Close relevant buffers first
2. **Use the cleanup command** (`SPC p c`) before deleting large projects
3. **Restart Emacs periodically** if you frequently create/delete projects

## Configuration Location

The protection is implemented in:
- **`~/.doom.d/config/core/my-project-cleanup-config.el`**
- **Loaded in**: `~/.doom.d/config.el`

## How It Works

1. **Automatic timers** clean up invalid references periodically
2. **Hooks** detect when you're working with deleted projects
3. **Advice** wraps projectile functions to auto-clean
4. **Enhanced configs** for recentf/treemacs to handle missing files gracefully

You should never see "file not found" errors for deleted projects again!
