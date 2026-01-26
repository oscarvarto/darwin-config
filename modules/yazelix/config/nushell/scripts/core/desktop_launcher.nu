#!/usr/bin/env nu

# Yazelix Desktop Launcher
# Ensures we're in the yazelix environment and calls launch script directly

def main [] {
    # Set environment
    let yazelix_dir = $"($nu.home-path)/.config/yazelix"
    $env.YAZELIX_DIR = $yazelix_dir

    # Pass home directory as launch_cwd so desktop entry opens in ~/ instead of yazelix directory
    ^nu $"($yazelix_dir)/nushell/scripts/core/launch_yazelix.nu" ($nu.home-path)
}
