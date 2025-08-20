# doom-emacs

Stow package for managing Doom Emacs configuration.

## Overview

This package manages your complete Doom Emacs configuration located at `~/.doom.d`. It includes all the entry files and modular configuration organized by functionality areas.

## Configuration Structure

```
~/.doom.d/
├── init.el          # Doom modules configuration
├── packages.el      # Package declarations and configuration
├── config.el        # Main configuration loader
├── custom.el        # Emacs custom variables
├── config/          # Modular configuration files
│   ├── ai/          # AI-related configuration (Tabnine, etc.)
│   ├── core/        # Core Emacs functionality
│   ├── jvm/         # JVM languages configuration
│   ├── languages/   # Programming language configurations
│   ├── lsp/         # Language Server Protocol configuration
│   ├── misc/        # Miscellaneous configurations
│   ├── ui/          # User interface customizations
│   └── writing/     # Writing and documentation tools
├── snippets/        # YASnippet templates
├── keybindings.org  # Documentation of keybindings
├── lazy-load.org    # Lazy loading documentation
└── PROJECT-CLEANUP-GUIDE.md  # Project cleanup guidelines
```

## Features

- **Declarative Configuration**: All Doom Emacs settings version-controlled
- **Modular Organization**: Configuration split by functional areas
- **Stow Integration**: Seamless deployment with other stow packages
- **System Restoration**: Easy configuration restore on new systems
- **Version Control**: Full history of configuration changes

## Usage

### Deploy Configuration
```bash
# Deploy doom-emacs configuration
manage-aux-scripts deploy doom-emacs

# Or deploy all packages including doom-emacs
manage-aux-scripts deploy
```

### Update Configuration
1. Edit files in `~/darwin-config/stow/doom-emacs/.doom.d/`
2. Test changes in Doom Emacs
3. Commit changes to version control
4. Configuration is automatically active via stow symlinks

### Remove Configuration
```bash
# Remove stow symlinks (keeps original files)
manage-aux-scripts remove doom-emacs
```

### System Restoration Workflow
On a new system or after fresh installation:

1. Clone darwin-config repository
2. Deploy doom-emacs stow package: `manage-aux-scripts deploy doom-emacs`  
3. Install Doom Emacs itself (if not already installed)
4. Run Doom sync: `doom sync`
5. Configuration is ready to use

## Configuration Guidelines

### File Organization
- **Entry files** (`init.el`, `packages.el`, `config.el`) at root level
- **Specific configurations** in `config/` subdirectories by topic
- **Snippets** in dedicated `snippets/` directory
- **Documentation** files (`.org`, `.md`) alongside configuration

### Making Changes
1. Edit configuration files in the stow directory
2. Changes are immediately active due to symlink structure
3. Test thoroughly in Doom Emacs
4. Commit changes to preserve configuration history

### AI Configuration
- Tabnine configuration lives in `config/ai/tabnine/`
- Follow the established pattern for AI tool configurations

## Integration

### With Doom Emacs
- This package provides the complete `~/.doom.d` configuration
- Works with standard Doom Emacs installation and commands
- Compatible with `doom sync`, `doom upgrade`, etc.

### With Other Stow Packages
- Complements other development tool configurations
- Part of the unified darwin-config management system
- Consistent with other declarative tool setups

### With Nix Configuration
- Integrates with your broader nix-managed system
- Configuration files can reference nix-installed packages
- Consistent environment across nix and Emacs tooling

## Error Resilience

### Configuration Validation
- Use `elisp-formatter.js` to validate S-expression balance
- Test configuration in Doom Emacs before committing
- Keep backup of working configuration

### Recovery
- Stow symlinks preserve original structure
- Can quickly rollback via version control
- Remove/redeploy cycle for clean restoration

### Common Issues
- **Syntax errors**: Use elisp formatter to validate files
- **Missing packages**: Check `packages.el` declarations
- **Module conflicts**: Verify `init.el` module configuration
- **Path issues**: Ensure proper file organization

## Dependencies

### Required
- Doom Emacs installation
- Stow package manager
- Git for version control

### Optional
- `elisp-formatter.js` for syntax validation
- Various Emacs packages as declared in `packages.el`
- External tools referenced in configuration

## Maintenance

### Regular Tasks
- Review and update package declarations
- Clean up unused configuration files
- Update documentation when adding new modules
- Validate elisp syntax after major changes

### Version Control
- Commit configuration changes frequently
- Use descriptive commit messages
- Tag stable configuration states
- Maintain clean git history

## Tips

- **Modular approach**: Keep related configuration in same subdirectory
- **Documentation**: Document complex configurations inline
- **Testing**: Test changes incrementally rather than large batches
- **Backup**: Keep known-good configuration states in version control
- **Performance**: Use lazy loading for large configurations
- **Compatibility**: Ensure configurations work in both terminal and GUI Emacs

## References

- [Doom Emacs Documentation](https://github.com/doomemacs/doomemacs)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/)
- Your darwin-config repository structure and conventions
