# Common Patterns

### Adding New Software
1. Check if available as Nix package (`modules/packages.nix`)
2. If GUI app, add to Homebrew casks (`modules/casks.nix`)
3. If CLI tool, add to Homebrew brews (`modules/brews.nix`)
4. Rebuild with `nb && ns`

### Managing Emacs Versions
1. Pin to current: `emacs-pin` (no args) - **automatically called after every `ns`**
2. Pin to specific: `emacs-pin abc123def`
3. Check status: `emacs-pin-status`
4. Unpin for latest: `emacs-unpin`
5. Rebuild: `nb && ns` (automatically pins Emacs after switch)

#### Emacs Pinning Behavior (Contributor Notes)
- Pin state files (in `~/.cache`):
  - `emacs-git-pin` (commit), `emacs-git-pin-hash` (SRI), `emacs-git-store-path` (built outPath)
- Behavior matrix:
  - Pinned + stored path exists → `configuredEmacs` re-exports that exact path; overlay updates do not rebuild.
  - Pinned + stored path missing (GC’d) → build latest overlay commit; after switch, `ns` auto-runs `emacs-pin` to lock to that new build.
  - Unpinned → always use latest overlay commit; `ns` auto-pins after successful switch.
- Scripts:
  - `emacs-pin` captures the already-built `configuredEmacs` outPath before changing pin state to avoid rebuild.
  - `emacs-pin-status` prints overlay commit, pinned commit, stored hash, and stored path if present.
- Caveat: Pinning to an older commit only avoids rebuild if that exact build already exists locally. Otherwise, next `ns` will build latest and auto-pin to it by design.

##### Impure vs. Pure Evaluation
- Why: Reusing a previously built Emacs relies on reading `~/.cache/emacs-git-store-path` during evaluation, which is an impure input.
- Default: `nb`/`ns` now default to impure evaluation so `configuredEmacs` can re-export the stored path when pinned and present (no rebuild on overlay updates).
- Force pure (reproducible eval, no reuse): add `--pure` or set `NS_IMPURE=0` when running `nb`/`ns`.
- Explicit impure: add `--impure` or set `NS_IMPURE=1`.
- CI guidance: prefer pure evaluation in CI or when you need strictly reproducible builds; expect Emacs to rebuild if inputs changed or the stored path is missing.

### Adding New Host/User
1. `nix run .#add-host -- --hostname HOST --user USER`
2. Configure host-specific settings in generated config
3. Test with `nix run .#configure-user -- --dry-run`
4. Apply with `nix run .#configure-user`

### Shell Customization
1. Edit appropriate shell config in `modules/`
2. Add aliases/functions to shell-specific sections
3. PATH changes go in `modules/path-config.nix`
4. Rebuild with `ns`
