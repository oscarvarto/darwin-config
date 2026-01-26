# Emacs Configuration (Stow)

This package deploys your Emacs configuration to `~/.emacs.d` using GNU Stow.

## Contents
- Copied from your current `~/.emacs.d`
- Excludes generated caches, binaries, and large tool directories

## Exclusions
Common runtime artifacts are intentionally excluded from version control:
- Package/build caches (e.g., `elpaca/`, `eln-cache/`, `.cache/`)
- Tree-sitter binaries (`tree-sitter/`)
- LSP and session state (`eclipse.jdt.ls/`, `.lsp-session-v1`, `workspace/`)
- Ephemeral state (`recentf.eld`, `projectile-bookmarks.eld`, `tramp`, `dape-breakpoints`)
- Compiled artifacts (`*.elc`, `*.eln`, `*.dylib`, `*.so`)

## Deploy
```bash
cd ~/darwin-config/stow
stow -t ~ emacs
```
