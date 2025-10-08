# uv2nix Migration Status

## Goal
Adopt a uv2nix-driven Python environment inside `darwin-config` so heavy GUI dependencies (PyQt6, PyQt6-WebEngine, SciPy, etc.) use prebuilt wheels and the configuration stays reproducible. This replaces the hand-written `python3.withPackages` block with an environment derived from `python-env/pyproject.toml` and `uv.lock`.

Repositories & docs:
- uv2nix introduction: https://pyproject-nix.github.io/uv2nix
- pyproject.nix build infrastructure: https://pyproject-nix.github.io/pyproject.nix/build.html
- Current workspace sources live in `python-env/pyproject.toml` and `python-env/uv.lock`.

## Commands Tried So Far
### Successful / useful
- `uv lock` (inside `python-env`) — regenerates `uv.lock` after editing dependencies.  
- `uv lock --upgrade --preview-features extra-build-dependencies` — forced uv to refresh the lock and pulled in extra wheels (meson, meson-python).  
- `uv lock --preview-features extra-build-dependencies` — same as above but without forcing upgrades; good for re-locking after small edits.

### Ineffective / unexpected
- `[tool.uv.extra-build-dependencies]` in `pyproject.toml` — listed extra build wheels for docopt/epc/path-and-address/scipy. Wheels still failed because the feature seems ignored unless uv is actually building the project (uv2nix may not honor it).  
- `uv lock --preview-features extra-build-dependencies` *plus* `[tool.uv.preview]` — attempted to enable the feature globally; uv rejected the TOML shape.  
- `uv lock --force` — uv CLI has no `--force`; errored out.  
- `uv lock --upgrade --preview-features ...` worked but didn't stick the extra build deps.  
- Overriding via `workspace.mkPyprojectOverlay { extraBuildDependencies = ...; }` — uv2nix’s API doesn’t expose that attribute; raised “unexpected argument” error.

## Current State
- `flake.nix`, `system.nix`, and `modules/packages.nix` now route both the system and Home Manager package sets through uv2nix, pyproject-nix, and the uv lock file.  
- We derive a base virtualenv (`pythonEnvBase`) and patch in local xontrib overrides.  
- Certain legacy deps (docopt, epc, path-and-address) still fail at build time because `setuptools` is missing when they build from sdists. SciPy also expects `mesonpy`. Attempted fixes via `tool.uv.extra-build-dependencies` were ignored, and passing overrides directly in Nix currently throws attribute errors.

## Next Steps / Open Issues
1. Resolve the missing build backends:
   - Investigate pyproject.nix `passthru.dependencies` overrides or use `pkgs.python3Packages`.  
   - Alternatively, add a small overlay of prebuilt wheels (or vendor their `setup.cfg` metadata).
2. Restore evaluation of `darwin-config-env` (currently blocked by the attr errors around `path-and-address` overrides).
3. Once the Python env is stable, trim the temporary hacks or document why particular overrides exist.
4. Re-run `ns` / `nix build .#darwinConfigurations.predator.system` to confirm the whole stack succeeds.

Keep this file updated as we iterate so we can pick up the migration in a later session.
