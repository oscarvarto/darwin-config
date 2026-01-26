#!/bin/bash

# Emacs Clean Reinstall Script
# This script safely removes all compiled packages and caches to force a fresh reinstall
# Your configuration files (init.el, my/*.el) are preserved

set -e  # Exit on error

EMACS_DIR="$HOME/.emacs.d"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "=============================================="
echo "  Emacs Clean Reinstall Script"
echo "=============================================="
echo ""
echo "This will delete:"
echo "  - $EMACS_DIR/elpaca/          (all packages)"
echo "  - $EMACS_DIR/.lsp-session-*   (LSP caches)"
echo "  - $EMACS_DIR/workspace/       (LSP workspace)"
echo "  - $EMACS_DIR/.cache/          (general cache)"
echo "  - $EMACS_DIR/.lsp-mode-*      (rebuild markers)"
echo ""
echo "Your configuration files will NOT be touched:"
echo "  - $EMACS_DIR/init.el"
echo "  - $EMACS_DIR/my/*.el"
echo ""

# Check if Emacs is running
if pgrep -x "Emacs" > /dev/null 2>&1 || pgrep -x "emacs" > /dev/null 2>&1; then
    echo "⚠️  WARNING: Emacs is currently running!"
    echo "Please close all Emacs instances before continuing."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

# Confirmation
read -p "Continue with cleanup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."
echo ""

# Step 1: Create backups
echo "Step 1: Creating backups..."
if [ -d "$EMACS_DIR/my" ]; then
    cp -r "$EMACS_DIR/my" "$EMACS_DIR/my.backup.$TIMESTAMP"
    echo "  ✓ Backed up: my/ -> my.backup.$TIMESTAMP/"
fi

if [ -f "$EMACS_DIR/init.el" ]; then
    cp "$EMACS_DIR/init.el" "$EMACS_DIR/init.el.backup.$TIMESTAMP"
    echo "  ✓ Backed up: init.el -> init.el.backup.$TIMESTAMP"
fi
echo ""

# Step 2: Delete elpaca packages
echo "Step 2: Deleting elpaca packages..."
if [ -d "$EMACS_DIR/elpaca" ]; then
    rm -rf "$EMACS_DIR/elpaca"
    echo "  ✓ Deleted: elpaca/"
else
    echo "  ℹ  elpaca/ not found (already clean)"
fi
echo ""

# Step 3: Delete LSP caches
echo "Step 3: Deleting LSP caches..."
deleted_count=0

# LSP session files
for file in "$EMACS_DIR"/.lsp-session-*; do
    if [ -e "$file" ]; then
        rm -rf "$file"
        echo "  ✓ Deleted: $(basename "$file")"
        ((deleted_count++))
    fi
done

# Workspace directory
if [ -d "$EMACS_DIR/workspace" ]; then
    rm -rf "$EMACS_DIR/workspace"
    echo "  ✓ Deleted: workspace/"
    ((deleted_count++))
fi

# Cache directory
if [ -d "$EMACS_DIR/.cache" ]; then
    rm -rf "$EMACS_DIR/.cache"
    echo "  ✓ Deleted: .cache/"
    ((deleted_count++))
fi

# Rebuild marker files
for file in "$EMACS_DIR"/.lsp-mode-*; do
    if [ -e "$file" ]; then
        rm -f "$file"
        echo "  ✓ Deleted: $(basename "$file")"
        ((deleted_count++))
    fi
done

if [ $deleted_count -eq 0 ]; then
    echo "  ℹ  No cache files found (already clean)"
fi
echo ""

# Step 4: Delete native compilation cache (if exists)
echo "Step 4: Checking native compilation cache..."
if [ -d "$EMACS_DIR/eln-cache" ]; then
    rm -rf "$EMACS_DIR/eln-cache"
    echo "  ✓ Deleted: eln-cache/"
elif [ -d "$EMACS_DIR/var/eln-cache" ]; then
    rm -rf "$EMACS_DIR/var/eln-cache"
    echo "  ✓ Deleted: var/eln-cache/"
else
    echo "  ℹ  No native compilation cache found"
fi
echo ""

# Verify cleanup
echo "=============================================="
echo "  Cleanup Complete!"
echo "=============================================="
echo ""
echo "Verification:"

if [ ! -d "$EMACS_DIR/elpaca" ]; then
    echo "  ✓ elpaca/ removed"
else
    echo "  ✗ elpaca/ still exists!"
fi

if ! ls "$EMACS_DIR"/.lsp-session-* 2>/dev/null; then
    echo "  ✓ LSP session files removed"
else
    echo "  ✗ LSP session files still exist!"
fi

if [ -f "$EMACS_DIR/init.el" ]; then
    echo "  ✓ init.el preserved"
else
    echo "  ✗ init.el missing!"
fi

if [ -d "$EMACS_DIR/my" ]; then
    echo "  ✓ my/ directory preserved"
else
    echo "  ✗ my/ directory missing!"
fi

echo ""
echo "Backups created:"
echo "  - $EMACS_DIR/my.backup.$TIMESTAMP/"
echo "  - $EMACS_DIR/init.el.backup.$TIMESTAMP"
echo ""
echo "=============================================="
echo "  Next Steps:"
echo "=============================================="
echo ""
echo "1. Start Emacs:"
echo "   $ emacs"
echo ""
echo "2. Wait for package installation (2-5 minutes):"
echo "   - Elpaca will download and compile all packages"
echo "   - Watch for: 'Elpaca processed N packages'"
echo "   - lsp-mode will compile with lsp-use-plists=t"
echo "   - Advice will be installed BEFORE compilation"
echo ""
echo "3. Restart Emacs again after packages finish installing"
echo ""
echo "4. Open a Java file and verify:"
echo "   ✓ Should see: 'Using emacs-lsp-booster for...'"
echo "   ✓ Should NOT see: 'Error processing message (wrong-type-argument hash-table-p...)'"
echo "   ✓ Should NOT see: 'Yasnippet is not installed...'"
echo ""
echo "If you encounter any issues, your backups are available."
echo ""
