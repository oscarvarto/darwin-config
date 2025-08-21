# Themes Directory

This directory contains custom themes and color schemes for Doom Emacs.

## Contents

- Custom Emacs themes (`.el` files)
- Terminal color schemes
- Syntax highlighting configurations
- Color palette definitions

## Usage

Custom themes can be loaded in Doom Emacs by:
1. Adding the theme directory to the load path
2. Using `load-theme` to activate them

Example configuration:
```elisp
(add-to-list 'custom-theme-load-path (expand-file-name "~/doom-extra-files/themes"))
```

## Theme Development

When creating custom themes:
- Follow Emacs theme conventions
- Test with both light and dark system preferences
- Consider accessibility (contrast ratios)
- Document theme-specific features
