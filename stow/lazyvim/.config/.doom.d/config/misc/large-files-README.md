# Large Files Configuration

This configuration improves Emacs performance when working with large files by automatically disabling TreeSitter and other heavy features that can make Emacs slow or unresponsive.

## Features

### Automatic Detection
- **Default threshold**: 1MB (1024 * 1024 bytes)
- **Automatic detection**: When opening files or switching buffers
- **Features automatically disabled**:
  - TreeSitter (tree-sitter-mode, tree-sitter-hl-mode)
  - TreeSitter-related functions (ts-fold, combobulate, line-reminder)
  - LSP Mode
  - Autocompletion (company-mode, corfu-mode)
  - Syntax checking (flycheck-mode)
  - Additional rendering optimizations

### Configurable Thresholds
You can adjust the threshold according to your needs by editing the variable in the configuration file:

```elisp
;; Available options (uncomment the one you prefer):
(setq my/large-file-threshold (* 512 1024))   ; 512KB
(setq my/large-file-threshold (* 2 1024 1024)) ; 2MB (more conservative)
(setq my/large-file-threshold (* 5 1024 1024)) ; 5MB (less restrictive)
```

### Available Commands

#### `my/toggle-large-file-mode`
- **Keybinding**: `SPC t L`
- **Function**: Manually toggles large file mode for the current buffer
- **Useful when**: You want to force optimization for a specific file

#### `my/set-large-file-threshold`
- **Command**: `M-x my/set-large-file-threshold`
- **Function**: Interactively changes the file size threshold
- **Input**: Size in bytes

### Integration with Existing TreeSitter

The configuration automatically integrates with your existing TreeSitter configuration (`my-tree-sitter-config.el`) by overriding the `my/should-enable-tree-sitter-p` function to include file size checking.

### Informative Messages

When a large file is detected, you'll see a message like:
```
Large file detected (2.5M bytes). Disabling heavy features for better performance.
TreeSitter and heavy features disabled for large file. File size: 2.5M
```

### Optional Features

In the configuration file there are some commented features you can enable if you need even more optimization:

```elisp
;; Completely disable syntax highlighting
(when (bound-and-true-p font-lock-mode)
  (font-lock-mode -1))

;; Switch to fundamental-mode for very large files
(fundamental-mode)

;; Disable undo history
(setq-local buffer-undo-list t)
```

## Use Cases

### Log Files
- Large log files (>1MB) will open quickly without TreeSitter
- You maintain the ability to navigate and edit
- No lag when scrolling

### Data Files
- Large CSV, JSON, XML files
- Very long configuration files
- Database dumps

### Large Code Files
- Automatically generated files
- Files with lots of repetitive code
- Minified libraries

## Advanced Customization

### Modify Disabled Features
You can modify the `my/large-file-disabled-features` list to add or remove features:

```elisp
(setq my/large-file-disabled-features
      '(tree-sitter-mode
        tree-sitter-hl-mode
        ;; Add more features here
        your-custom-mode))
```

### Custom Hooks
You can add your own logic:

```elisp
(add-hook 'find-file-hook
          (lambda ()
            (when (my/large-file-p)
              ;; Your custom logic here
              )))
```

## Troubleshooting

### If a file is not detected as large
- Verify that the file actually exists on disk
- Use `M-x my/toggle-large-file-mode` to activate manually
- Adjust the threshold with `M-x my/set-large-file-threshold`

### If you want to temporarily reactivate TreeSitter
- Use `M-x tree-sitter-mode` to reactivate TreeSitter
- Or use `M-x my/toggle-large-file-mode` to disable large file mode

### For debugging
- Use `M-x my/large-file-p` to check if the current buffer is considered a large file
- Check messages in the `*Messages*` buffer

