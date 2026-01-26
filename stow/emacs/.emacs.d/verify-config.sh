#!/bin/bash

# Emacs Configuration Verification Script
# Checks that lsp-mode configuration is correct before cleanup

EMACS_DIR="$HOME/.emacs.d"
LSP_CONFIG="$EMACS_DIR/my/my-lsp.el"

echo "=============================================="
echo "  Emacs Configuration Verification"
echo "=============================================="
echo ""

# Check if config file exists
if [ ! -f "$LSP_CONFIG" ]; then
    echo "❌ ERROR: $LSP_CONFIG not found!"
    exit 1
fi

echo "Checking $LSP_CONFIG..."
echo ""

# Check 1: lsp-use-plists is set early
echo "✓ Check 1: lsp-use-plists set before lsp-mode loads"
if grep -q "^(setq lsp-use-plists t)" "$LSP_CONFIG"; then
    line_num=$(grep -n "^(setq lsp-use-plists t)" "$LSP_CONFIG" | cut -d: -f1)
    echo "  ✅ Found at line $line_num: (setq lsp-use-plists t)"
else
    echo "  ❌ NOT FOUND: (setq lsp-use-plists t)"
    echo "     This must be set BEFORE use-package lsp-mode!"
    exit 1
fi
echo ""

# Check 2: lsp-enable-snippet is set
echo "✓ Check 2: lsp-enable-snippet disabled (fixes yasnippet warning)"
if grep -q "^(setq lsp-enable-snippet nil)" "$LSP_CONFIG"; then
    line_num=$(grep -n "^(setq lsp-enable-snippet nil)" "$LSP_CONFIG" | cut -d: -f1)
    echo "  ✅ Found at line $line_num: (setq lsp-enable-snippet nil)"
else
    echo "  ⚠️  NOT FOUND: (setq lsp-enable-snippet nil)"
    echo "     You may see yasnippet warnings"
fi
echo ""

# Check 3: lsp-booster advice is defined
echo "✓ Check 3: lsp-booster advice functions defined"
if grep -q "defun lsp-booster--advice-json-parse" "$LSP_CONFIG"; then
    line_num=$(grep -n "defun lsp-booster--advice-json-parse" "$LSP_CONFIG" | cut -d: -f1)
    echo "  ✅ Found at line $line_num: lsp-booster--advice-json-parse"
else
    echo "  ❌ NOT FOUND: lsp-booster--advice-json-parse"
    exit 1
fi

if grep -q "defun lsp-booster--advice-final-command" "$LSP_CONFIG"; then
    line_num=$(grep -n "defun lsp-booster--advice-final-command" "$LSP_CONFIG" | cut -d: -f1)
    echo "  ✅ Found at line $line_num: lsp-booster--advice-final-command"
else
    echo "  ❌ NOT FOUND: lsp-booster--advice-final-command"
    exit 1
fi
echo ""

# Check 4: Advice is installed (not in with-eval-after-load)
echo "✓ Check 4: Advice installed BEFORE lsp-mode package loads"
advice_line=$(grep -n "advice-add 'lsp-resolve-final-command" "$LSP_CONFIG" | cut -d: -f1)
package_line=$(grep -n "dolist.*lsp-mode" "$LSP_CONFIG" | cut -d: -f1)

if [ -n "$advice_line" ] && [ -n "$package_line" ]; then
    echo "  Last advice at line: $advice_line"
    echo "  Package loading at line: $package_line"

    if [ "$advice_line" -lt "$package_line" ]; then
        echo "  ✅ Advice is installed BEFORE packages load"
    else
        echo "  ❌ ERROR: Advice at line $advice_line is AFTER package loading (line $package_line)"
        echo "     Advice must be installed BEFORE lsp-mode loads!"
        exit 1
    fi
else
    echo "  ⚠️  Could not verify line numbers, but functions are defined"
fi
echo ""

# Check 5: No advice in with-eval-after-load
echo "✓ Check 5: No advice inside (with-eval-after-load 'lsp-mode)"
if grep -A 50 "(with-eval-after-load 'lsp-mode" "$LSP_CONFIG" | grep -q "lsp-booster--advice"; then
    echo "  ⚠️  WARNING: Found lsp-booster advice inside with-eval-after-load block!"
    echo "     This will cause errors. Advice should be BEFORE use-package."
    exit 1
else
    echo "  ✅ No lsp-booster advice in with-eval-after-load blocks"
fi
echo ""

# Check 6: emacs-lsp-booster binary exists
echo "✓ Check 6: emacs-lsp-booster binary available"
if command -v emacs-lsp-booster &> /dev/null; then
    booster_path=$(which emacs-lsp-booster)
    echo "  ✅ Found: $booster_path"
else
    echo "  ⚠️  NOT FOUND: emacs-lsp-booster"
    echo "     Install with: cargo install emacs-lsp-booster"
    echo "     lsp-mode will still work, but without performance boost"
fi
echo ""

# Summary
echo "=============================================="
echo "  Verification Complete!"
echo "=============================================="
echo ""
echo "Configuration looks correct! ✅"
echo ""
echo "You can now safely run:"
echo "  ~/.emacs.d/cleanup-and-reinstall.sh"
echo ""
echo "This will:"
echo "  1. Delete all packages and caches"
echo "  2. Force fresh reinstall with correct settings"
echo "  3. lsp-mode will compile with lsp-use-plists=t"
echo "  4. Advice will be installed BEFORE compilation"
echo ""
