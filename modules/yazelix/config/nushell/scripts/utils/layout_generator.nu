#!/usr/bin/env nu
# Copy Zellij layouts to merged config directory

use constants.nu *

const widget_tray_placeholder = "__YAZELIX_WIDGET_TRAY__"

def build_widget_tray [widget_tray: list<string>]: nothing -> string {
    let allowed = ["layout", "editor", "shell", "term", "cpu", "ram"]
    mut parts = []
    for widget in $widget_tray {
        if not ($widget in $allowed) {
            let allowed_str = ($allowed | str join ", ")
            print $"Warning: Invalid zellij.widget_tray entry: ($widget) (allowed: ($allowed_str))"
            continue
        }
        let part = match $widget {
            "layout" => "{swap_layout}"
            "editor" => "#[fg=#00ff88,bold][editor: {command_editor}]"
            "shell" => "#[fg=#00ff88,bold][shell: {command_shell}]"
            "term" => "#[fg=#00ff88,bold][term: {command_term}]"
            "cpu" => "{command_cpu}"
            "ram" => "{command_ram}"
            _ => ""
        }
        $parts = ($parts | append $part)
    }
    $parts | str join " "
}

# Copy a layout file to the target directory
# Parameters:
#   source_layout: path to the template layout file
#   target_layout: path to the output layout file
#   widget_tray: list of widgets to show in the status bar
export def generate_layout [
    source_layout: string
    target_layout: string
    widget_tray: list<string> = ["layout", "editor", "shell", "term", "cpu", "ram"]
]: nothing -> nothing {
    let target_path = ($target_layout | path expand)

    # Remove existing file if it exists (may be read-only from previous nix builds)
    if ($target_path | path exists) {
        rm -f $target_path
    }

    let content = (open ($source_layout | path expand))
    if ($content | str contains $widget_tray_placeholder) {
        let tray = build_widget_tray $widget_tray
        let updated = ($content | str replace -a $widget_tray_placeholder $tray)
        $updated | save --force $target_path
        return
    }

    # No placeholder found, just copy the file
    $content | save --force $target_path
}

# Copy all layout files to the target directory
export def generate_all_layouts [
    layouts_source_dir: string
    layouts_target_dir: string
    widget_tray: list<string> = ["layout", "editor", "shell", "term", "cpu", "ram"]
]: nothing -> nothing {
    # Ensure target directory and all parent directories exist
    let target_dir = ($layouts_target_dir | path expand)
    if not ($target_dir | path exists) {
        mkdir $target_dir
    }

    # List of layout files to process
    let layout_files = [
        "yzx_side.kdl"
        "yzx_no_side.kdl"
        "yzx_side.swap.kdl"
        "yzx_no_side.swap.kdl"
        "yzx_sweep_test.kdl"
    ]

    # Copy each layout file
    for file in $layout_files {
        let source = ($layouts_source_dir | path join $file)
        let target = ($layouts_target_dir | path join $file)

        if ($source | path exists) {
            generate_layout $source $target $widget_tray
            print $"Generated layout: ($target)"
        }
    }
}
