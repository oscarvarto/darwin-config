# Agent Guidelines (scope: entire ~/.emacs.d repo)
## Build / Lint / Test
- Primary check: run `./verify-config.sh` from repo root.
- Reinstall flow: `./cleanup-and-reinstall.sh` then restart Emacs.
- Ad-hoc byte-compile a module: `emacs --batch -L my -l my-defaults -f batch-byte-compile my/foo.el`.
- Launch Emacs noninteractively for smoke test: `emacs --batch -Q -l init.el`.
- Single module check: `./verify-config.sh` exits nonzero on ordering mistakes.

## Style
- Emacs Lisp files begin with `;; -*- lexical-binding: t; no-byte-compile: t; -*-`.
- Keep module names and provides prefixed with `my-`; one feature per file.
- Use `use-package` with :ensure/:demand and group related customizations or hooks.
- Prefer `setq` configuration above `use-package` blocks when order matters.
- Imports via `require` or load-path additions should live at top-level.
- Favor descriptive function names, avoid single-letter bindings.
- Error handling uses guard forms (`when-let`, conditional exits) instead of silent failures.
- Maintain comment banners (`;; ===`) for major sections; wrap at ~80 chars.
- No Cursor or Copilot rule files exist; adhere solely to this guidance.
- Commit only relevant Emacs Lisp; avoid adding byte-compiled artifacts.
