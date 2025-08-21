# Doom Extra Files

This stow package manages additional files for Doom Emacs that are stored outside the main `.doom.d` configuration directory.

## Purpose

The `~/doom-extra-files` directory contains supplementary files, templates, snippets, and other resources that complement the main Doom Emacs configuration but don't belong in the `.doom.d` directory structure.

## Usage

Deploy this package with:
```bash
stow -t ~ doom-extra-files
```

This will create symlinks from `~/darwin-config/stow/doom-extra-files/doom-extra-files/` to `~/doom-extra-files/`.

## Structure

- `~/doom-extra-files/` - Root directory for extra Doom Emacs files
  - Add subdirectories as needed for organization (e.g., `templates/`, `snippets/`, `themes/`, etc.)

## Benefits

- Version controlled alongside the main Doom configuration
- Easy to deploy and manage with stow
- Keeps the main `.doom.d` directory clean and focused
- Can be easily backed up and restored as part of the darwin-config repository
