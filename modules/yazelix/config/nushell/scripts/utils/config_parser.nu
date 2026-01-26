#!/usr/bin/env nu
# Configuration parser for yazelix TOML files

# Parse yazelix configuration file and extract settings
export def parse_yazelix_config [] {
    let yazelix_dir = "~/.config/yazelix" | path expand

    # Check for config override first (for testing)
    let config_to_read = if ($env.YAZELIX_CONFIG_OVERRIDE? | is-not-empty) {
        $env.YAZELIX_CONFIG_OVERRIDE
    } else {
        # Determine which config file to use
        let toml_file = ($yazelix_dir | path join "yazelix.toml")
        let default_toml = ($yazelix_dir | path join "yazelix_default.toml")

        if ($toml_file | path exists) {
            $toml_file
        } else if ($default_toml | path exists) {
            # Auto-create yazelix.toml from default (copy raw to preserve comments)
            print "📝 Creating yazelix.toml from yazelix_default.toml..."
            cp $default_toml $toml_file
            print "✅ yazelix.toml created\n"
            $toml_file
        } else {
            error make {msg: "No yazelix configuration file found (yazelix_default.toml is missing)"}
        }
    }

    # Parse TOML configuration (Nushell auto-parses TOML files)
    let raw_config = open $config_to_read

    # Extract and return values
    let editor_command = ($raw_config.editor?.command? | default null)
    let normalized_editor_command = if ($editor_command | describe) == "string" and ($editor_command | str trim | is-empty) {
        null
    } else {
        $editor_command
    }
    let editor_theme = ($raw_config.editor?.theme? | default null)
    let normalized_editor_theme = if ($editor_theme | describe) == "string" and ($editor_theme | str trim | is-empty) {
        null
    } else {
        $editor_theme
    }
    let editor_command_key = ($raw_config.editor?.command_key? | default ":")
    let normalized_editor_command_key = if ($editor_command_key | describe) == "string" and ($editor_command_key | str trim | is-not-empty) {
        $editor_command_key
    } else {
        ":"
    }

    {
        recommended_deps: ($raw_config.core?.recommended_deps? | default true),
        yazi_extensions: ($raw_config.core?.yazi_extensions? | default true),
        yazi_media: ($raw_config.core?.yazi_media? | default false),
        debug_mode: ($raw_config.core?.debug_mode? | default false),
        skip_welcome_screen: ($raw_config.core?.skip_welcome_screen? | default false),

        editor_command: $normalized_editor_command,
        helix_theme: $normalized_editor_theme,
        helix_command_key: $normalized_editor_command_key,
        enable_sidebar: ($raw_config.editor?.enable_sidebar? | default true),

        default_shell: ($raw_config.shell?.default_shell? | default "nu"),
        extra_shells: ($raw_config.shell?.extra_shells? | default []),
        enable_atuin: ($raw_config.shell?.enable_atuin? | default false),

        preferred_terminal: ($raw_config.terminal?.preferred_terminal? | default "ghostty"),
        extra_terminals: ($raw_config.terminal?.extra_terminals? | default []),
        terminal_config_mode: ($raw_config.terminal?.config_mode? | default "yazelix"),
        cursor_trail: ($raw_config.terminal?.cursor_trail? | default "random"),
        transparency: ($raw_config.terminal?.transparency? | default "medium"),

        disable_zellij_tips: ($raw_config.zellij?.disable_tips? | default true),
        zellij_rounded_corners: ($raw_config.zellij?.rounded_corners? | default true),
        persistent_sessions: ($raw_config.zellij?.persistent_sessions? | default false),
        session_name: ($raw_config.zellij?.session_name? | default "yazelix"),
        widget_tray: ($raw_config.zellij?.widget_tray? | default ["layout", "editor", "shell", "term", "cpu", "ram"]),
        zellij_theme: ($raw_config.zellij?.theme? | default "default"),

        yazi_plugins: ($raw_config.yazi?.plugins? | default ["git" "starship"]),
        yazi_theme: ($raw_config.yazi?.theme? | default "default"),
        yazi_sort_by: ($raw_config.yazi?.sort_by? | default "alphabetical"),

        ascii_art_mode: ($raw_config.ascii?.mode? | default "static"),

        config_file: $config_to_read
    }
}
