#!/usr/bin/env nu
# Yazelix Command Suite
# Consolidated commands for managing and interacting with yazelix

use ../utils/config_manager.nu *
use ../utils/constants.nu *
use ../utils/version_info.nu *
use ../utils/config_parser.nu parse_yazelix_config
use ./start_yazelix.nu [start_yazelix_session]

# =============================================================================
# YAZELIX COMMANDS WITH NATIVE SUBCOMMAND SUPPORT
# =============================================================================

# Yazelix Command Suite - Yazi + Zellij + Helix integrated terminal environment
#
# Manage yazelix sessions, run diagnostics, and configure your setup.
# Supports: bash, nushell, fish, zsh
#
# Common commands:
#   yzx launch    - Start a new yazelix session
#   yzx doctor    - Run health checks
#   yzx profile   - Profile launch performance
#   yzx test      - Run test suite
#   yzx lint      - Validate script syntax
#   yzx versions  - Show tool versions
export def yzx [
    --version (-V)  # Show version information
] {
    if $version {
        print $"Yazelix ($YAZELIX_VERSION)"
        return
    }
    help yzx
}

# Elevator pitch: Why Yazelix
export def "yzx why" [] {
    print "Yazelix is a reproducible terminal IDE (Yazi + Zellij + Helix) with:"
    print "• Zero‑conflict keybindings, zjstatus, smooth Yazi↔editor flows"
    print "• Top terminals (Ghostty/WezTerm/Kitty/Alacritty) and shells (Bash/Zsh/Fish/Nushell)"
    print "• One‑file config (Nix) with sane defaults and curated packs"
    print "• Remote‑ready over SSH; same superterminal on barebones hosts"
    print "• Git and tooling preconfigured (lazygit, starship, zoxide, carapace)"
    print "Get everything running in <10 minutes. No extra deps, only Nix."
    print "Install once, get the same environment everywhere."
}

# Show configuration status (canonical, no aliases)
export def "yzx config_status" [shell?: string] {
    if ($shell | is-empty) {
        show_config_status ~/.config/yazelix
    } else {
        let config_file = ($SHELL_CONFIGS | get $shell | str replace "~" $env.HOME)
        if not ($config_file | path exists) {
            print $"❌ Config file not found: ($config_file)"
            return
        }
        let section = extract_yazelix_section $config_file
        if $section.exists {
            print $"=== Yazelix Section in ($shell) ==="
            print $section.content
            print "=================================="
        } else {
            print $"❌ No yazelix section found in ($config_file)"
        }
        $section
    }
}

# List available versions
export def "yzx versions" [] {
    nu ~/.config/yazelix/nushell/scripts/utils/version_info.nu
}

# Show system info
export def "yzx info" [] {
    # Parse configuration using the shared module
    let config = parse_yazelix_config

    print "=== Yazelix Information ==="
    print $"Version: ($YAZELIX_VERSION)"
    print $"Description: ($YAZELIX_DESCRIPTION)"
    print $"Directory: ($YAZELIX_CONFIG_DIR | str replace "~" $env.HOME)"
    print $"Logs: ($YAZELIX_LOGS_DIR | str replace "~" $env.HOME)"
    print $"Default Shell: ($config.default_shell)"
    print $"Preferred Terminal: ($config.preferred_terminal)"
    print $"Persistent Sessions: ($config.persistent_sessions)"
    let persistent_sessions = ($config.persistent_sessions | default false)
    let persistent_enabled = if ($persistent_sessions | describe) == "bool" {
        $persistent_sessions
    } else {
        $persistent_sessions == "true"
    }
    if $persistent_enabled {
        print $"Session Name: ($config.session_name)"
    }
    print "=========================="
}

# Launch yazelix
export def "yzx launch" [
    --here             # Start in current terminal instead of launching new terminal
    --path(-p): string # Start in specific directory
    --home             # Start in home directory
    --terminal(-t): string  # Override terminal selection (for sweep testing)
    --verbose          # Enable verbose logging
] {
    use ~/.config/yazelix/nushell/scripts/utils/nix_detector.nu ensure_nix_available
    ensure_nix_available

    let verbose_mode = $verbose or ($env.YAZELIX_VERBOSE? == "true")
    if $verbose_mode {
        print "🔍 yzx launch: verbose mode enabled"
    }

    if $here {
        # Start in current terminal without spawning a new process
        $env.YAZELIX_ENV_ONLY = "false"

        # Determine directory override: explicit --home or --path, else let start_yazelix handle it
        let cwd_override = if $home {
            $env.HOME
        } else if ($path != null) {
            $path
        } else {
            null
        }

        if $verbose {
            if ($cwd_override != null) {
                start_yazelix_session $cwd_override --verbose
            } else {
                start_yazelix_session --verbose
            }
        } else {
            if ($cwd_override != null) {
                start_yazelix_session $cwd_override
            } else {
                start_yazelix_session
            }
        }
        return
    }

    # Launch new terminal
    let launch_cwd = if $home {
            $env.HOME
        } else if ($path | is-not-empty) {
            $path
        } else {
            pwd
        }

        let launch_script = $"($env.HOME)/.config/yazelix/nushell/scripts/core/launch_yazelix.nu"
        let base_args = [$launch_script]
        let mut_args = if ($launch_cwd | is-not-empty) {
            $base_args | append $launch_cwd
        } else {
            $base_args
        }
        let mut_args = if ($terminal | is-not-empty) {
            $mut_args | append "--terminal" | append $terminal
        } else {
            $mut_args
        }
        if $verbose_mode {
            let run_args = ($mut_args | append "--verbose")
            print $"⚙️ Executing launch_yazelix.nu - cwd: ($launch_cwd)"
            ^nu ...$run_args
        } else {
            ^nu ...$mut_args
        }
}

# Load yazelix environment without UI
export def "yzx env" [
    --no-shell(-n)  # Keep current shell instead of launching configured shell
    --command(-c): string  # Run a command in the Yazelix environment
] {
    use ~/.config/yazelix/nushell/scripts/utils/nix_detector.nu ensure_nix_available
    ensure_nix_available

    let config = parse_yazelix_config
    let original_dir = (pwd)
    let extra_shells_str = if ($config.extra_shells | is-empty) { "" } else { $config.extra_shells | str join "," }
    let editor_cmd = ($config.editor_command? | default "hx")
    let resolved_editor = if ($editor_cmd | describe) == "string" and ($editor_cmd | str trim | is-empty) {
        "hx"
    } else {
        $editor_cmd
    }
    let helix_theme = ($config.helix_theme? | default "")
    let helix_command_key = ($config.helix_command_key? | default ":")
    let resolved_helix_command_key = if ($helix_command_key | describe) == "string" and ($helix_command_key | str trim | is-not-empty) {
        $helix_command_key
    } else {
        ":"
    }
    let base_env = {
        YAZELIX_ENV_ONLY: "true",
        YAZELIX_SKIP_WELCOME: "true",
        YAZELIX_DIR: $"($env.HOME)/.config/yazelix",
        IN_YAZELIX_SHELL: "true",
        YAZELIX_DEFAULT_SHELL: $config.default_shell,
        YAZELIX_PREFERRED_TERMINAL: $config.preferred_terminal,
        YAZI_CONFIG_HOME: $"($env.HOME)/.local/share/yazelix/configs/yazi",
        EDITOR: $resolved_editor,
        YAZELIX_HELIX_COMMAND_KEY: $resolved_helix_command_key,
        NUSHELL_THEME: "dark"
    }
    let env_vars = if ($helix_theme | is-not-empty) {
        $base_env | upsert YAZELIX_HELIX_THEME $helix_theme
    } else {
        $base_env
    }

    # Ensure environment setup (initializers, hooks) is up to date
    with-env $env_vars {
        nu $"($env.HOME)/.config/yazelix/nushell/scripts/setup/environment.nu" $"($env.HOME)/.config/yazelix" $config.recommended_deps $config.enable_atuin $config.default_shell $config.debug_mode $extra_shells_str $config.skip_welcome_screen $config.ascii_art_mode
    }

    if ($command | is-not-empty) {
        with-env $env_vars {
            ^bash -lc $"cd '($original_dir)' && ($command)"
        }
        return
    }

    if $no_shell {
        print "Yazelix environment available in current shell (no extra activation needed)."
        return
    }

    let shell_name = ($config.default_shell? | default "nu" | str downcase)
    let shell_command = match $shell_name {
        "nu" => ["nu" "--login"]
        "bash" => ["bash" "--login"]
        "fish" => ["fish" "-l"]
        "zsh" => ["zsh" "-l"]
        _ => [$shell_name]
    }
    let shell_exec = ($shell_command | first)
    let command_str = ($shell_command | str join " ")
    let exec_command = $"cd '($original_dir)' && exec ($command_str)"
    with-env ($env_vars | merge {SHELL: $shell_exec}) {
        try {
            ^bash -lc $exec_command
        } catch {|err|
            print $"❌ Failed to launch configured shell: ($err.msg)"
            print "   Tip: rerun with 'yzx env --no-shell' to stay in your current shell."
            exit 1
        }
    }
}

# Helper: Kill the current Zellij session
def kill_current_zellij_session [] {
    try {
        let current_session = (zellij list-sessions
            | lines
            | where $it =~ 'current'
            | first
            | split row " "
            | first)

        # Strip ANSI escape codes
        let clean_session = ($current_session | str replace -ra '\u001b\[[0-9;]*[A-Za-z]' '')

        if ($clean_session | is-empty) {
            print "⚠️  No current Zellij session detected"
            return null
        }

        print $"Killing Zellij session: ($clean_session)"
        zellij kill-session $clean_session
        return $clean_session
    } catch {|err|
        print $"❌ Failed to kill session: ($err.msg)"
        return null
    }
}

# Restart yazelix
export def "yzx restart" [] {
    # Detect if we're in a Yazelix-controlled terminal (launched via wrapper)
    let is_yazelix_terminal = ($env.YAZELIX_TERMINAL_CONFIG_MODE? | is-not-empty)

    # Provide appropriate messaging
    if $is_yazelix_terminal {
        print "🔄 Restarting Yazelix..."
    } else {
        print "🔄 Restarting Yazelix \(opening new window\)..."
    }

    # Launch new terminal window
    yzx launch

    # Wait for new session to spawn
    sleep 1sec

    # Kill old session (Yazelix terminals will close, vanilla stays open)
    kill_current_zellij_session
}

# Run health checks and diagnostics
export def "yzx doctor" [
    --verbose(-v)  # Show detailed information
    --fix(-f)      # Attempt to auto-fix issues
] {
    use ../utils/doctor.nu run_doctor_checks
    run_doctor_checks $verbose $fix
}

# Update guidance (Yazelix is now part of the main Nix config)
export def "yzx update" [] {
    print "Yazelix dependencies are managed via the main Nix configuration."
    print "Run updates from the darwin-config repo (e.g., nix flake update + rebuild)."
}

# Run configuration sweep tests across shell/terminal combinations
export def "yzx sweep" [] {
    print "Run 'yzx sweep --help' to see available subcommands"
}

# Test all shell combinations
export def "yzx sweep shells" [
    --verbose(-v)  # Show detailed output
] {
    use ../dev/test_config_sweep.nu run_all_sweep_tests

    if $verbose {
        run_all_sweep_tests --verbose
    } else {
        run_all_sweep_tests
    }
}

# Test all terminal launches
export def "yzx sweep terminals" [
    --verbose(-v)       # Show detailed output
    --delay: int = 3    # Delay between terminal launches in seconds
] {
    use ../dev/test_config_sweep.nu run_all_sweep_tests

    run_all_sweep_tests --visual --verbose=$verbose --visual-delay $delay
}

# Run all sweep tests (shells + terminals)
export def "yzx sweep all" [
    --verbose(-v)       # Show detailed output
    --delay: int = 3    # Delay between terminal launches in seconds
] {
    print "=== Running All Sweep Tests ==="
    print "Phase 1: Shell combinations (fast)"
    print ""

    yzx sweep shells --verbose=$verbose

    print ""
    print "=== Phase 2: Terminal launches (slow) ==="
    print ""

    yzx sweep terminals --verbose=$verbose --delay $delay
}

# Run Yazelix test suite
export def "yzx test" [
    --verbose(-v)  # Show detailed test output
    --new-window(-n)  # Run tests in a new Yazelix window
    --all(-a)  # Include visual terminal sweep tests
] {
    use ../utils/test_runner.nu run_all_tests
    run_all_tests --verbose=$verbose --new-window=$new_window --all=$all
}

# Validate syntax of all Nushell scripts
export def "yzx lint" [
    --verbose(-v)  # Show detailed output for each file
] {
    if $verbose {
        nu $"($env.HOME)/.config/yazelix/nushell/scripts/dev/validate_syntax.nu" --verbose
    } else {
        nu $"($env.HOME)/.config/yazelix/nushell/scripts/dev/validate_syntax.nu"
    }
}

# Benchmark terminal launch performance
export def "yzx bench" [
    --iterations(-n): int = 1  # Number of iterations per terminal
    --terminal(-t): string     # Test only specific terminal
    --verbose(-v)              # Show detailed output
] {
    mut args = ["--iterations", $iterations]

    if ($terminal | is-not-empty) {
        $args = ($args | append ["--terminal", $terminal])
    }

    if $verbose {
        $args = ($args | append "--verbose")
    }

    nu $"($env.HOME)/.config/yazelix/nushell/scripts/dev/benchmark_terminals.nu" ...$args
}

# Profile launch sequence and identify bottlenecks
export def "yzx profile" [
    --cold(-c)        # Profile cold launch (informational)
] {
    use ../utils/profile.nu *

    if $cold {
        profile_cold_launch
    } else {
        profile_launch
    }
}
