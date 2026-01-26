#!/usr/bin/env nu
# Yazi Configuration Generator
# Generates yazi configs from yazelix defaults + dynamic settings from yazelix.toml

use ../utils/constants.nu [YAZELIX_STATE_DIR]
use ../utils/config_parser.nu parse_yazelix_config

# Ensure directory exists
def ensure_dir [path: string] {
    let dir = ($path | path dirname)
    if not ($dir | path exists) {
        mkdir $dir
    }
}

# Simple copy of config file
def copy_config_file [source_dir: string, merged_dir: string, file_name: string, --quiet] {
    let source_path = $"($source_dir)/yazelix_($file_name)"
    let merged_path = $"($merged_dir)/($file_name)"

    if not $quiet {
        print $"   📄 Linking ($file_name)..."
    }

    # Use symlinks to avoid copying from the Nix store each launch.
    # Use -sfn: -f forces overwrite, -n prevents following existing symlinks to directories
    ^ln -sfn $source_path $merged_path

    if not $quiet {
        print $"     ✅ ($file_name) linked"
    }
}

# Copy plugins directory (preserves user-installed plugins)
def copy_plugins_directory [source_dir: string, merged_dir: string, user_plugins: list, --quiet] {
    let source_plugins = $"($source_dir)/plugins"
    let merged_plugins = $"($merged_dir)/plugins"

    # Yazi's native plugin locations
    let yazi_plugins_dir = ($env.HOME | path join ".config" "yazi" "plugins")
    let yazi_packages_dir = ($env.HOME | path join ".local" "state" "yazi" "packages")

    if not $quiet {
        print "   📁 Copying plugins directory..."
    }

    # Ensure plugins directory exists
    if not ($merged_plugins | path exists) {
        mkdir $merged_plugins
    }

    # Link yazelix bundled plugins (overwrites if they exist)
    # This preserves user-installed plugins that yazelix doesn't provide
    if ($source_plugins | path exists) {
        let bundled_plugins = (ls $source_plugins | where {|entry| $entry.type in ["dir", "symlink"] } | get name)

        for plugin_path in $bundled_plugins {
            let plugin_name = ($plugin_path | path basename)
            let target = $"($merged_plugins)/($plugin_name)"

            # Link fresh version using -sfn: -f forces overwrite, -n prevents following existing symlinks to directories
            ^ln -sfn $plugin_path $target
        }

        if not $quiet {
            print "     ✅ Yazelix plugins linked"
        }
    }

    # Link user-installed plugins from yazi's native directories
    # This makes plugins installed via `ya pkg add` available to yazelix
    for plugin_name in $user_plugins {
        let target = $"($merged_plugins)/($plugin_name).yazi"

        # Skip if already linked (from bundled plugins)
        if ($target | path exists) {
            continue
        }

        # Check yazi's native plugins directory first
        let yazi_plugin = $"($yazi_plugins_dir)/($plugin_name).yazi"
        if ($yazi_plugin | path exists) {
            ^ln -sfn $yazi_plugin $target
            if not $quiet {
                print $"     ✅ Linked user plugin: ($plugin_name) [from yazi plugins]"
            }
            continue
        }

        # Check yazi's installed packages directory
        if ($yazi_packages_dir | path exists) {
            let package_dirs = (ls $yazi_packages_dir | where type == "dir" | get name)
            mut found = false
            for pkg_dir in $package_dirs {
                let pkg_plugin = $"($pkg_dir)/($plugin_name).yazi"
                if ($pkg_plugin | path exists) {
                    ^ln -sfn $pkg_plugin $target
                    if not $quiet {
                        print $"     ✅ Linked user plugin: ($plugin_name) [from yazi packages]"
                    }
                    $found = true
                    break
                }
            }
            if $found {
                continue
            }
        }
    }

    if not $quiet {
        print "     ✅ User plugins linked"
    }
}

# Generate yazi.toml with dynamic settings from yazelix.toml
def generate_yazi_toml [source_dir: string, merged_dir: string, theme: string, sort_by: string, user_plugins: list, --quiet] {
    let source_path = $"($source_dir)/yazelix_yazi.toml"
    let merged_path = $"($merged_dir)/yazi.toml"

    if not $quiet {
        print "   📄 Generating yazi.toml with dynamic settings..."
    }

    # Read and parse base config
    let base_config = open $source_path

    # Remove git fetchers if git plugin is not in the list
    let config_without_git_fetchers = if ("git" not-in $user_plugins) {
        $base_config | reject plugin?
    } else {
        $base_config
    }

    # Add dynamic settings from yazelix.toml
    let config_with_settings = ($config_without_git_fetchers | upsert mgr {
        sort_by: $sort_by
    })

    # Add theme at root level
    let final_config = ($config_with_settings | insert theme $theme)

    # Generate header
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let header = [
        "# ========================================"
        "# AUTO-GENERATED YAZI CONFIG"
        "# ========================================"
        "# This file is automatically generated by Yazelix."
        "# Do not edit directly - changes will be lost!"
        "#"
        "# To customize, edit:"
        "#   ~/.config/yazelix/yazelix.toml"
        "#   [yazi] theme = \"...\""
        "#   [yazi] sort_by = \"...\""
        "#"
        $"# Generated: ($timestamp)"
        "# ========================================"
        ""
    ] | str join "\n"

    # Write final config
    let config_content = ($final_config | to toml)
    $"($header)($config_content)" | save -f $merged_path

    if not $quiet {
        print $"     ✅ yazi.toml generated with theme: ($theme), sort_by: ($sort_by)"
    }
}

# Generate init.lua dynamically based on plugin configuration
def generate_init_lua [merged_dir: string, user_plugins: list, --quiet] {
    let plugins_dir = $"($merged_dir)/plugins"

    # Additional plugin directories to check (yazi's native locations)
    let yazi_plugins_dir = ($env.HOME | path join ".config" "yazi" "plugins")
    let yazi_packages_dir = ($env.HOME | path join ".local" "state" "yazi" "packages")

    # Helper: Check if plugin exists in any known location
    let plugin_exists = {|name|
        # Check yazelix merged plugins directory
        if ($"($plugins_dir)/($name).yazi" | path exists) {
            return true
        }
        # Check yazi's native plugins directory
        if ($"($yazi_plugins_dir)/($name).yazi" | path exists) {
            return true
        }
        # Check yazi's installed packages (subdirectories with hash names)
        if ($yazi_packages_dir | path exists) {
            let package_dirs = (ls $yazi_packages_dir | where type == "dir" | get name)
            for pkg_dir in $package_dirs {
                if ($"($pkg_dir)/($name).yazi" | path exists) {
                    return true
                }
            }
        }
        false
    }

    # Core plugins - always loaded, cannot be disabled
    let core_plugins = ["sidebar-status", "auto-layout"]

    # Combine core + user plugins
    let all_plugins = ($core_plugins | append $user_plugins | uniq)

    # Check for missing plugins and warn
    let missing = ($all_plugins | where {|p|
        not (do $plugin_exists $p)
    })

    if ($missing | is-not-empty) {
        print $"⚠️  Warning: Missing plugins in yazelix.toml: ($missing | str join ', ')"
        print "   Install with: ya pkg add <owner/repo>"
        print "   Or remove from yazelix.toml [yazi] plugins list"
    }

    # Only load plugins that exist
    let valid_plugins = ($all_plugins | where {|p|
        (do $plugin_exists $p)
    })

    # Generate require/setup statements (guard against plugins without setup)
    let requires = ($valid_plugins | each {|name|
        let comment = if ($name in $core_plugins) {
            "-- Core plugin (always loaded)"
        } else {
            "-- User plugin (from yazelix.toml)"
        }
        [
            $comment
            "do"
            ('  local plugin = require("' + $name + '")')
            "  if type(plugin) == 'table' and plugin.setup then"
            "    plugin:setup()"
            "  end"
            "end"
        ] | str join "\n"
    } | str join "\n\n")

    # Generate final init.lua content
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let header = [
        "-- ========================================"
        "-- AUTO-GENERATED YAZI INIT.LUA"
        "-- ========================================"
        "-- This file is automatically generated by Yazelix."
        "-- Do not edit directly - changes will be lost!"
        "--"
        "-- To customize plugins, edit:"
        "--   ~/.config/yazelix/yazelix.toml"
        "--   [yazi] plugins = [...]"
        "--"
        $"-- Generated: ($timestamp)"
        "-- ========================================"
        ""
    ] | str join "\n"

    let init_content = $"($header)($requires)\n"

    # Write init.lua
    let init_path = $"($merged_dir)/init.lua"
    $init_content | save -f $init_path

    if not $quiet {
        print $"   ✅ Generated init.lua with ($valid_plugins | length) plugins"
    }
}

# Main function: Generate Yazi configuration
export def generate_merged_yazi_config [yazelix_dir: string, --quiet] {
    # Parse yazelix config to get settings
    let config = parse_yazelix_config
    let user_plugins = $config.yazi_plugins
    let theme = $config.yazi_theme
    let sort_by = $config.yazi_sort_by

    # Define paths
    let state_dir = ($YAZELIX_STATE_DIR | path expand)
    let merged_config_dir = $"($state_dir)/configs/yazi"
    let source_config_dir = $"($yazelix_dir)/configs/yazi"

    if not $quiet {
        print "🔄 Generating Yazi configuration..."
    }

    # Ensure output directory exists
    ensure_dir $"($merged_config_dir)/yazi.toml"

    # Generate yazi.toml with dynamic settings from yazelix.toml
    generate_yazi_toml $source_config_dir $merged_config_dir $theme $sort_by $user_plugins --quiet=$quiet

    # Copy other config files (simple copy, no merging)
    let config_files = ["keymap.toml", "theme.toml"]
    for file in $config_files {
        copy_config_file $source_config_dir $merged_config_dir $file --quiet=$quiet
    }

    # Copy plugins directory
    copy_plugins_directory $source_config_dir $merged_config_dir $user_plugins --quiet=$quiet

    # Generate init.lua dynamically based on plugin configuration
    generate_init_lua $merged_config_dir $user_plugins --quiet=$quiet

    if not $quiet {
        print $"✅ Yazi configuration generated successfully!"
        print $"   📁 Config saved to: ($merged_config_dir)"
    }

    $merged_config_dir
}

# Export main function for external use
export def main [yazelix_dir: string, --quiet] {
    generate_merged_yazi_config $yazelix_dir --quiet=$quiet | ignore
}
