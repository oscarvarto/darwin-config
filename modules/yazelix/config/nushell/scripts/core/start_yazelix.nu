#!/usr/bin/env nu
# ~/.config/yazelix/nushell/scripts/core/start_yazelix.nu

use ../utils/config_parser.nu parse_yazelix_config
use ../utils/constants.nu [ZELLIJ_CONFIG_PATHS, YAZI_CONFIG_PATHS, YAZELIX_ENV_VARS]
use ../utils/nix_detector.nu ensure_nix_available
use ../setup/zellij_config_merger.nu generate_merged_zellij_config
use ../setup/yazi_config_merger.nu generate_merged_yazi_config

def _start_yazelix_impl [cwd_override?: string, --verbose] {
    # Capture original directory before any cd commands
    let original_dir = pwd

    # Try to set up Nix environment automatically when outside Yazelix/nix shells
    use ../utils/nix_env_helper.nu ensure_nix_in_environment

    let already_in_env = (
        ($env.IN_YAZELIX_SHELL? == "true")
        or ($env.IN_NIX_SHELL? | is-not-empty)
    )

    if not $already_in_env {
        # If automatic setup fails, fall back to the detector with user interaction
        if not (ensure_nix_in_environment) {
            ensure_nix_available
        }
    }

    let verbose_mode = $verbose or ($env.YAZELIX_VERBOSE? == "true")
    if $verbose_mode {
        print "🔍 start_yazelix: verbose mode enabled"
    }

    # Resolve HOME using Nushell's built-in
    let home = $env.HOME
    if ($home | is-empty) or (not ($home | path exists)) {
        print "Error: Cannot resolve HOME directory"
        exit 1
    }

    # Set absolute path for Yazelix directory
    let yazelix_dir = $"($home)/.config/yazelix"

    # Navigate to Yazelix directory
    if not ($yazelix_dir | path exists) {
        print $"Error: Cannot find Yazelix directory at ($yazelix_dir)"
        exit 1
    }

    cd $yazelix_dir

    # Parse configuration using the shared module
    let config = parse_yazelix_config
    let extra_shells_str = if ($config.extra_shells | is-empty) { "" } else { $config.extra_shells | str join "," }
    let launch_shell_override = ($env.YAZELIX_LAUNCH_SHELL? | default "")
    let resolved_default_shell = if ($launch_shell_override | is-not-empty) {
        $launch_shell_override
    } else {
        $config.default_shell
    }
    let editor_cmd = ($config.editor_command? | default "hx")
    let resolved_editor = if ($editor_cmd | describe) == "string" and ($editor_cmd | str trim | is-empty) {
        "hx"
    } else {
        $editor_cmd
    }
    $env.EDITOR = $resolved_editor

    # Initialize shell hooks and environment setup (creates initializers, handles welcome screen)
    if $verbose_mode {
        print "🧩 Running Yazelix environment setup..."
    }
    with-env {YAZELIX_DIR: $yazelix_dir} {
        nu $"($yazelix_dir)/nushell/scripts/setup/environment.nu" $yazelix_dir $config.recommended_deps $config.enable_atuin $config.default_shell $config.debug_mode $extra_shells_str $config.skip_welcome_screen $config.ascii_art_mode
    }

    # Generate merged Yazi configuration (doesn't need zellij)
    print "🔧 Preparing Yazi configuration..."
    let merged_yazi_dir = if $verbose_mode {
        generate_merged_yazi_config $yazelix_dir
    } else {
        generate_merged_yazi_config $yazelix_dir --quiet
    }
    
    # Ensure Zellij is available before we proceed
    if (which zellij | is-empty) {
        print ""
        print "❌ zellij command not found."
        print "   Ensure zellij is installed and available in PATH."
        print ""
        exit 1
    }

    # Zellij config directory (merged output)
    let merged_zellij_dir = ($ZELLIJ_CONFIG_PATHS.merged_config_dir | path expand)

    # Determine which directory to use as default CWD
    # Priority: 1. cwd_override parameter 2. YAZELIX_LAUNCH_CWD env var 3. original directory
    let working_dir = if ($cwd_override | is-not-empty) {
        $cwd_override
    } else if ($env.YAZELIX_LAUNCH_CWD? | is-not-empty) {
        $env.YAZELIX_LAUNCH_CWD
    } else {
        $original_dir
    }

    # Check for layout override (for testing), default to constant
    let layout = if ($env.ZELLIJ_DEFAULT_LAYOUT? | is-not-empty) {
        $env.ZELLIJ_DEFAULT_LAYOUT
    } else {
        $YAZELIX_ENV_VARS.ZELLIJ_DEFAULT_LAYOUT
    }
    # Resolve layout to an absolute file path so it works even if user config overrides layout_dir
    let layout_path = if ($layout | str contains "/") or ($layout | str ends-with ".kdl") {
        $layout
    } else {
        $"($merged_zellij_dir)/layouts/($layout).kdl"
    }

    if $verbose_mode {
        print "🔧 Preparing Zellij configuration..."
    }

    generate_merged_zellij_config $yazelix_dir | ignore

    if not ($layout_path | path exists) {
        print $"❌ Zellij layout not found: ($layout_path)"
        print "   Check your yazelix layouts and configuration."
        exit 1
    }

    let persistent_sessions = ($config.persistent_sessions | default false)
    let persistent_enabled = if ($persistent_sessions | describe) == "bool" {
        $persistent_sessions
    } else {
        $persistent_sessions == "true"
    }

    let zellij_args = if $persistent_enabled {
        [
            "--config-dir" $merged_zellij_dir
            "attach"
            "-c" $config.session_name
            "options"
            "--default-cwd" $working_dir
            "--default-layout" $layout_path
            "--pane-frames" "false"
            "--default-shell" $resolved_default_shell
        ]
    } else {
        [
            "--config-dir" $merged_zellij_dir
            "options"
            "--default-cwd" $working_dir
            "--default-layout" $layout_path
            "--pane-frames" "false"
            "--default-shell" $resolved_default_shell
        ]
    }

    if $verbose_mode {
        print $"🔁 zellij args: ($zellij_args | str join ' ')"
    }

    let yazi_config_home = ($YAZELIX_ENV_VARS.YAZI_CONFIG_HOME | path expand)
    let helix_theme = ($config.helix_theme? | default "")
    let helix_command_key = ($config.helix_command_key? | default ":")
    let resolved_helix_command_key = if ($helix_command_key | describe) == "string" and ($helix_command_key | str trim | is-not-empty) {
        $helix_command_key
    } else {
        ":"
    }
    let base_env = {
        HOME: $home,
        IN_YAZELIX_SHELL: "true",
        YAZELIX_DIR: $yazelix_dir,
        YAZELIX_DEFAULT_SHELL: $resolved_default_shell,
        YAZI_CONFIG_HOME: $yazi_config_home,
        EDITOR: $resolved_editor,
        YAZELIX_HELIX_COMMAND_KEY: $resolved_helix_command_key,
        NUSHELL_THEME: "dark"
    }
    let env_vars = if ($helix_theme | is-not-empty) {
        $base_env | upsert YAZELIX_HELIX_THEME $helix_theme
    } else {
        $base_env
    }

    # Run zellij directly with Yazelix environment variables set.
    with-env $env_vars {
        ^zellij ...$zellij_args

        let exit_code = $env.LAST_EXIT_CODE
        if $exit_code != 0 {
            print $"❌ Zellij exited with code ($exit_code)."
            try {
                input "Press Enter to close..."
            } catch {
                # Ignore non-interactive shells.
            }
        }
    }
}

export def start_yazelix_session [cwd_override?: string, --verbose] {
    if ($cwd_override | is-not-empty) {
        if $verbose {
            _start_yazelix_impl $cwd_override --verbose
        } else {
            _start_yazelix_impl $cwd_override
        }
    } else if $verbose {
        _start_yazelix_impl --verbose
    } else {
        _start_yazelix_impl
    }
}

export def main [cwd_override?: string, --verbose] {
    if ($cwd_override | is-not-empty) {
        if $verbose {
            _start_yazelix_impl $cwd_override --verbose
        } else {
            _start_yazelix_impl $cwd_override
        }
    } else if $verbose {
        _start_yazelix_impl --verbose
    } else {
        _start_yazelix_impl
    }
}
