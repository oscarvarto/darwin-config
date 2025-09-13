# Lisp Language Support for LazyVim

This configuration adds comprehensive support for Lisp family languages in Neovim using LazyVim, with special emphasis on Emacs Lisp integration with your Doom Emacs setup.

## Supported Languages

- **Emacs Lisp** (.el files) - Full integration with Doom Emacs
- **Clojure** (.clj, .cljs, .cljc files) - Enhanced REPL support
- **Common Lisp** (.lisp, .lsp, .cl files) - Basic syntax support
- **Scheme** (.scm, .ss, .rkt files) - Racket and MIT Scheme support
- **Fennel** (.fnl files) - Lua Lisp variant

## Key Features

### General Lisp Features
- **Parinfer** - Smart structural editing that maintains proper parentheses
- **Rainbow Delimiters** - Color-coded parentheses for better readability
- **S-expression text objects** - Navigate and manipulate Lisp forms easily
- **Treesitter integration** - Advanced syntax highlighting and code understanding
- **Conjure** - Interactive REPL evaluation for multiple Lisp dialects

### Emacs Lisp Specific Features
- **Doom Emacs integration** - Direct interaction with running Emacs instance
- **elisp-formatter integration** - Uses your custom elisp-formatter.js tool
- **Auto-formatting on save** - Keeps your Elisp code properly formatted
- **Syntax validation** - Real-time checking of Elisp code structure
- **Documentation lookup** - Access Emacs help system from within Neovim

## Key Bindings

### General Lisp Bindings (all Lisp languages)
- `<localleader>ee` - Evaluate current form/selection
- `<localleader>er` - Evaluate root form
- `<localleader>eb` - Evaluate entire buffer
- `<localleader>ef` - Evaluate file
- `<localleader>cs` - Connect to REPL
- `<localleader>cq` - Quit REPL connection
- `K` - Documentation lookup
- `<localleader>w(` - Wrap word in parentheses
- `<localleader>w[` - Wrap word in brackets
- `<localleader>w{` - Wrap word in braces

### S-expression Navigation
- `<localleader>)` - Emit tail element (barf)
- `<localleader>(` - Capture next element (slurp)
- `<localleader>}` - Emit head element
- `<localleader>{` - Capture previous element

### Emacs Lisp Specific Bindings
- `<localleader>cf` - Format buffer with elisp-formatter
- `<localleader>cc` - Check syntax with elisp-formatter
- `<localleader>dr` - Reload Doom Emacs configuration
- `<localleader>ds` - Sync Doom Emacs configuration

## User Commands

### Emacs Lisp Commands
- `:ElispEval [code]` - Evaluate Elisp code in running Emacs
- `:ElispFormat` - Format current buffer using elisp-formatter
- `:ElispCheck` - Check syntax of current buffer

## Configuration Options

### Auto-formatting
Auto-formatting on save is enabled by default for Elisp files. To disable:
```lua
vim.g.elisp_auto_format = false
```

### Parinfer Mode
Parinfer is set to "smart" mode by default. You can change this in the configuration:
- `"indent"` - Indentation drives structure
- `"paren"` - Parentheses drive structure  
- `"smart"` - Intelligent hybrid mode (recommended)

## Requirements

### System Dependencies
- **Emacs** - Required for Emacs Lisp evaluation and documentation
- **emacsclient** - For communicating with running Emacs instance
- **elisp-formatter.js** - Your custom Elisp formatter (already installed)
- **clojure-lsp** - LSP server for Clojure (installed via Mason)
- **clj-kondo** - Clojure linter (installed via Mason)

### Optional Dependencies
- **mit-scheme** - For Scheme REPL support
- **leiningen** or **clojure CLI** - For Clojure development
- **rlwrap** - Better REPL experience for some Lisps

## File Detection

The configuration automatically detects and sets the correct filetype for:
- `*.el`, `*.emacs` → elisp
- `*.clj`, `*.cljs`, `*.cljc` → clojure
- `*.lisp`, `*.lsp`, `*.cl` → lisp
- `*.scm`, `*.ss`, `*.rkt` → scheme
- `*.fnl` → fennel
- Doom Emacs config files (`init.el`, `config.el`, `packages.el`)
- Files in `.emacs.d/` and `.doom.d/` directories

## Integration with Doom Emacs

When editing files in your `.doom.d` directory, additional commands become available:
- Evaluate code directly in your running Emacs instance
- Reload Doom configuration without leaving Neovim
- Access Emacs documentation system
- Auto-format using your elisp-formatter tool

## Troubleshooting

### Emacs Integration Not Working
1. Ensure Emacs is running as a server: `(server-start)` in Emacs
2. Test emacsclient: `emacsclient --eval "(+ 1 2)"`
3. Check that emacsclient is in your PATH

### Formatting Issues
1. Verify elisp-formatter.js is working: `elisp-formatter.js --help`
2. Check file permissions and PATH
3. Test on a simple .el file first

### REPL Connection Issues
1. For Clojure: Ensure a REPL is running (`lein repl` or `clj`)
2. For Scheme: Install and configure mit-scheme or your preferred implementation
3. Check Conjure logs: `:ConjureLogBuf`

## Extending the Configuration

You can extend this configuration by:
1. Adding more Lisp dialects to the filetype patterns
2. Configuring additional LSP servers in the `servers` table
3. Adding custom keybindings in the FileType autocmd
4. Modifying Conjure client settings for specific REPLs

The configuration is modular and can be easily customized to fit your specific Lisp development workflow.