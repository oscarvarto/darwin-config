# Testing & Validation

**There is no traditional test suite in this repository.** Instead, validation occurs through:

### Build Testing
- `nix flake check` - Validates all flake outputs and configurations
- `nix run .#build` - Tests that configuration builds successfully
- Configuration scripts include `--dry-run` modes for safe testing

### Configuration Validation
- Scripts validate host configs exist before applying
- Automatic rollback on build failures
- Syntax validation for complex configurations (Doom Emacs elisp)
