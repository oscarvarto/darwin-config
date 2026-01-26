# Lisp-like languages validation command line tools

Use the following command line tool in my path to validate and fix files after changes in elisp code. Note that this
rule doesn't apply to other programming languages like nix, java, etc. It's only useful for Emacs Lisp code.

elisp-formatter.js --help

🔧 Elisp Formatter - Advanced S-expression formatting with auto-repair

This tool formats Elisp files using Parinfer and can automatically repair structural issues like missing parentheses or
unbalanced expressions.

Usage: elisp-formatter [options] [command]

Check and format Elisp S-expressions using Parinfer with auto-repair capabilities

Options: -V, --version output the version number -h, --help display help for command

Commands: check <file> Check if S-expressions are balanced (validation only, no formatting) indent [options] <file>
  Format using Indent Mode (indentation drives structure, aggressive paren fixing) paren [options] <file> Format using
  Paren Mode (preserves parentheses, adjusts indentation) smart [options] <file> Format using Smart Mode (intelligent
  hybrid of indent and paren modes) elisp [options] <file> Format specifically for Elisp with custom rules (RECOMMENDED
  for .el files) batch [options] <directory> Process all .el files in directory (recursively scans subdirectories) help
  [command] display help for command

📖 FORMATTING MODES: • check - Validate S-expression balance (no changes made) • indent - Indentation drives structure
  (aggressive paren fixing) • paren - Parentheses drive structure (preserves existing parens) • smart - Intelligent
  hybrid mode (recommended for most cases) • elisp - Smart mode + Elisp-specific formatting rules (recommended) •
  batch - Process multiple .el files in a directory

🔧 AUTO-REPAIR FEATURES: The formatter can automatically fix common structural issues: • Missing closing parentheses •
  Unbalanced expressions • Malformed S-expressions

  Auto-repair is enabled by default. Use --no-auto-repair to disable.

📋 USAGE EXAMPLES:

  Basic formatting: elisp-formatter elisp my-config.el elisp-formatter smart my-config.el

  Check without modifying: elisp-formatter elisp my-config.el --check elisp-formatter check my-config.el

  Output to stdout: elisp-formatter elisp my-config.el --stdout

  Disable auto-repair: elisp-formatter elisp my-config.el --no-auto-repair

  Process entire directory: elisp-formatter batch ./config elisp-formatter batch ./config --mode elisp elisp-formatter
    batch ./config --check

  Advanced batch processing: elisp-formatter batch ./config --mode smart --no-auto-repair elisp-formatter batch ./config
    --stdout

🚀 RECOMMENDED WORKFLOWS:

  For custom Emacs configs: elisp-formatter batch ~/.emacs.d --mode elisp

  Quick validation: elisp-formatter batch . --check

  Safe preview before changes: elisp-formatter batch . --stdout | less

💡 TIP: Use 'elisp' mode for best results with Emacs Lisp files. It includes specialized formatting rules for Elisp
     constructs.

Always check for correctness after doing changes.
