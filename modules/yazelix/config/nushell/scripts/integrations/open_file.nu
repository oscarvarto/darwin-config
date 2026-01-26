#!/usr/bin/env nu
# Dynamic file opener that respects the configured editor
# This script is called by Yazi to open files

use ../utils/config_parser.nu parse_yazelix_config
use ../utils/logging.nu log_to_file
use ./yazi.nu open_file_with_editor

def main [file_path: path] {
    log_to_file "open_file.log" $"open_file.nu called with: ($file_path)"
    if ($env.EDITOR? | is-empty) {
        let config = parse_yazelix_config
        let editor = ($config.editor_command? | default "hx")
        $env.EDITOR = $editor
    }
    let editor = ($env.EDITOR? | default "not set")
    log_to_file "open_file.log" $"Resolved EDITOR=($editor)"
    print $"DEBUG: Opening file ($file_path) with EDITOR=($editor)"
    open_file_with_editor $file_path
}
