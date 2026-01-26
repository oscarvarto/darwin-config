# Configuration metadata for Yazelix
# Defines which config settings require a Nix rebuild

# Settings that require a rebuild when changed
# These settings affect package installation or Nix evaluation
export const REBUILD_REQUIRED_KEYS = [
    # Core packages and build settings
    "core.recommended_deps",
    "core.yazi_extensions",
    "core.yazi_media",

    # Editor command (may require package installation)
    "editor.command",

    # Shell packages
    "shell.extra_shells",
    "shell.enable_atuin",

    # Terminal packages
    "terminal.preferred_terminal",
    "terminal.extra_terminals"
]

# All other settings are runtime settings that apply immediately
# or on next session without requiring a rebuild
