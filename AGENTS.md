# Repository Guidelines

## Project Structure & Module Organization
- Root: `flake.nix` (entry), `flake.lock`, `system.nix` (host/system defaults).
- Nix modules: `modules/` (feature- and package-level `.nix` files).
- Dotfiles and app configs: `stow/` (GNU Stow packages; symlinked into `$HOME`).
- Helper scripts: `scripts/` (task automation) and `apps/` (nix-app entrypoints).
- Examples and docs: `examples/`, repo docs in `README.md` and sibling guides.

## Build, Test, and Development Commands
- Validate: `nix flake check` — runs flake checks and basic eval tests.
- Format: `nix fmt .` — formats Nix files.
- Dev shell: `nix develop` — enter shell with repo tools.
- Build: `nix run .#build` or alias `nb` (use `-v` for verbose).
- Build + switch: `nix run .#build-switch` or alias `ns` (`-v` supported).
- Stow deploy: `manage-stow-packages deploy` — symlink dotfiles/configs.
- Maintenance: `smart-gc status|dry-run|clean` — inspect/clean generations.

## Coding Style & Naming Conventions
- Nix: 2‑space indent, no trailing whitespace, kebab‑case filenames (e.g., `packages.nix`).
- Keep modules small, composable, and import via `modules/`.
- Scripts: prefer portable Bash; Nushell/Zsh allowed where appropriate. Use `set -euo pipefail` for Bash.
- Run `nix fmt .` before committing. Keep names descriptive: `emacs-pinning.nix`, `manage-*.nu`.

## Testing Guidelines
- Primary checks are functional builds:
  - `nix flake check` (must pass)
  - `nix run .#build` (should succeed)
- For stow packages, test locally: `stow -t ~ <package>` and verify symlinks.
- Add minimal example or doc updates in `examples/` when changing behavior.

## Commit & Pull Request Guidelines
- Messages: imperative, concise, explain the why (no strict Conventional Commits). Example: "Fix emacs pinning logic".
- Branches: `feat/<short>`, `fix/<short>`, `docs/<short>` recommended.
- PRs must include: summary, rationale, affected files/modules, test notes (`nix flake check` output or confirmation), and any screenshots for UI-facing tools.
- Update docs when changing `modules/`, `stow/`, or user workflows.

## Security & Configuration Tips
- Never commit secrets or private keys. Use `secret` CLI (`secret create|edit|status`) and agenix/1Password integration.
- Before pushing, sanitize: `nix run .#sanitize-repo`.
- Prefer adding credentials via the provided setup apps (see README) rather than inline config.

## Agent-Specific Instructions (from CLAUDE.md)
- Detection rule: implement multi-method checks for shell/process state (env vars + process scan + file locks). Clean up lock files in `/tmp` when done. See `agent-rules.md`.
- Stow usage: always target home with `stow -t ~ PACKAGE`; prefer `manage-stow-packages deploy`. Symlinked executables should land in `~/.local/share/bin`.
- Nix-embedded scripts: escape `${` and `$` correctly. Quick refs — double-quoted: `\"`, `\\`, `\${}`; indented strings: `''${}`, `''\n`.
- Emacs/Elisp edits: validate with `elisp-formatter elisp FILE --check` (or `smart`), ensure balanced parens; rebuild with `nb && ns`.
- Emacs pinning (contributors):
  - Use `emacs-pin` after a successful build to capture the exact store path and prevent rebuilds on overlay updates.
  - If pinned but the stored path was GC'd, the next `ns` builds the latest overlay commit and auto-pins to it after switch.
  - `emacs-pin-status` shows overlay vs pinned commits and whether a stored path is present.
- PATH edits belong in `modules/path-config.nix` (centralized precedence); apply with `ns`.
- Prefer fast Rust tools (`rg`, `fd`) over legacy `grep/find` in examples and scripts.
- Do not introduce NordVPN CLI dependencies (intentionally unsupported).
