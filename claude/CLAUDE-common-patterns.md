# Common Patterns

### Adding New Software
1. Check if available as Nix package (`modules/packages.nix`)
2. If GUI app, add to Homebrew casks (`modules/casks.nix`)
3. If CLI tool, add to Homebrew brews (`modules/brews.nix`)
4. Rebuild with `nb && ns`

### Managing Emacs Builds
1. (Optional) Warm up the overlay build with `nix run .#build-emacs-priority`.
2. Run `nb && ns` to rebuild and switch (installs Emacs + LaunchAgent helpers).
3. Deploy helper scripts with `manage-stow-packages deploy` so `e`, `t`, `et`, `emacsclient-gui`, etc. are on your `$PATH`.
4. Maintain your own configuration under `~/.emacs.d`, `~/.config/emacs`, or a custom stow package (e.g., `stow/emacs-config/.emacs.d`).

#### Emacs Build Behavior (Contributor Notes)
- We use the upstream `emacs-overlay` `emacs-git` derivation with native compilation, tree-sitter, ImageMagick, and Xwidgets enabled.
- Liquid Glass macOS Tahoe icons are copied from `modules/assets/icons` into `Emacs.app` during a lightweight post-build copy step.
- No pinning logic exists anymore; whatever commit your `flake.lock` references is what `nb/ns` evaluates against.
- To test another version, update `flake.lock` (e.g., `nix flake lock --update-input emacs-overlay`) or create a temporary overlay pin.

##### Impure vs. Pure Evaluation
- Default: `nb`/`ns` run with impure evaluation because helper scripts read files from the working tree via `DARWIN_CONFIG_PATH`.
- Force pure (fully reproducible evaluation): add `--pure` or set `NS_IMPURE=0` when running `nb`/`ns`.
- Explicit impure: add `--impure` or set `NS_IMPURE=1`.
- CI guidance: prefer pure evaluation in automated builds to avoid accidentally depending on local state.

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
