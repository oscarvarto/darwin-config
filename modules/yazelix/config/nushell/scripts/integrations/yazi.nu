#!/usr/bin/env nu
# Yazi integration utilities for Yazelix

use ../utils/logging.nu log_to_file
use zellij.nu [get_running_command, is_hx_running, is_nvim_running, open_in_existing_helix, open_in_existing_neovim, open_new_helix_pane, open_new_neovim_pane, find_and_focus_helix_pane, move_focused_pane_to_top, get_focused_pane_name, get_tab_name]

const MD_PREVIEW_PATH = "/tmp/yazelix-md-preview.path"

def is_markdown_file [file_path: path] {
    ($file_path | str downcase | str ends-with ".md")
}

# Render markdown preview in the aux pane using the piper previewer command
def render_markdown_in_aux_pane [file_path: path] {
    log_to_file "md_preview.log" $"render_markdown_in_aux_pane called with: ($file_path)"
    
    if not (is_markdown_file $file_path) {
        return
    }

    let expanded = ($file_path | path expand)
    
    # Save the path for potential re-rendering
    $expanded | save -f $MD_PREVIEW_PATH
    
    # Send glow command to the aux pane (rightmost pane)
    try {
        # Move focus to the right (aux pane)
        zellij action move-focus right
        sleep 50ms
        # Clear screen and run the configured piper preview command
        zellij action write-chars $"clear; nu ~/.config/yazelix/nushell/scripts/integrations/piper_preview.nu \"($expanded)\"\r"
        sleep 100ms
        # Return focus to editor pane (left)
        zellij action move-focus left
        log_to_file "md_preview.log" $"Preview rendered for: ($expanded)"
    } catch {|err|
        log_to_file "md_preview.log" $"Failed to render preview: ($err.msg)"
    }
}

# Toggle markdown preview - re-render current markdown file in aux pane
export def toggle_markdown_preview [] {
    log_to_file "md_preview.log" "toggle_markdown_preview called"

    # Check if we have a recent .md path
    let last_path = if ($MD_PREVIEW_PATH | path exists) {
        open $MD_PREVIEW_PATH | str trim
    } else {
        ""
    }

    if ($last_path | is-empty) or not ($last_path | path exists) {
        print "No markdown file to preview. Open a .md file first."
        log_to_file "md_preview.log" "No markdown file available to preview"
        return
    }

    # Render the preview in the aux pane (rightmost)
    try {
        zellij action move-focus right
        sleep 50ms
        # Clear screen and run the configured piper preview command
        zellij action write-chars $"clear; nu ~/.config/yazelix/nushell/scripts/integrations/piper_preview.nu \"($last_path)\"\r"
        sleep 100ms
        zellij action move-focus left
        print $"Markdown preview rendered for: ($last_path)"
        log_to_file "md_preview.log" $"Preview rendered for: ($last_path)"
    } catch {|err|
        print $"Failed to render preview: ($err.msg)"
        log_to_file "md_preview.log" $"Failed to render preview: ($err.msg)"
    }
}

# Check if the editor command is Helix (supports both simple names and full paths)
# This allows yazelix to work with "hx", "helix", "/nix/store/.../bin/hx", "/usr/bin/hx", etc.
def is_helix_editor [editor: string] {
    ($editor | str ends-with "/hx") or ($editor == "hx") or ($editor | str ends-with "/helix") or ($editor == "helix")
}

# Check if the editor command is Neovim (supports both simple names and full paths)
# This allows yazelix to work with "nvim", "neovim", "/nix/store/.../bin/nvim", "/usr/bin/nvim", etc.
def is_neovim_editor [editor: string] {
    ($editor | str ends-with "/nvim") or ($editor == "nvim") or ($editor | str ends-with "/neovim") or ($editor == "neovim")
}

# Sync yazi's directory to match the opened file's location
# This keeps yazi's view synchronized with the tab name and editor context
def sync_yazi_to_directory [file_path: path, yazi_id: string, log_file: string] {
    if ($yazi_id | is-empty) {
        log_to_file $log_file "YAZI_ID not set, skipping yazi navigation"
        return
    }

    let target_dir = if ($file_path | path type) == "dir" {
        $file_path
    } else {
        $file_path | path dirname
    }

    try {
        ya emit-to $yazi_id cd $target_dir
        log_to_file $log_file $"Successfully navigated yazi to directory: ($target_dir)"
    } catch {|err|
        log_to_file $log_file $"Failed to navigate yazi: ($err.msg)"
    }
}

# Navigate Yazi to the directory of the current Helix buffer
export def reveal_in_yazi [buffer_name: string] {
    log_to_file "reveal_in_yazi.log" $"reveal_in_yazi called with buffer_name: '($buffer_name)'"

    # Check if sidebar mode is enabled
    let sidebar_enabled = ($env.YAZELIX_ENABLE_SIDEBAR? | default "true") == "true"
    if (not $sidebar_enabled) {
        let friendly_msg = "📂 Reveal in Yazi (Alt+y) only works in sidebar mode. You're currently using no-sidebar mode."
        let tip_msg = "💡 Tip: Use Ctrl+y for file picking in no-sidebar mode, or enable sidebar mode in yazelix.toml"
        print $"($friendly_msg)\n($tip_msg)"
        log_to_file "reveal_in_yazi.log" "Sidebar mode disabled - reveal_in_yazi not available"
        return
    }

    if ($buffer_name | is-empty) {
        let error_msg = "Buffer name not provided"
        log_to_file "reveal_in_yazi.log" $"ERROR: ($error_msg)"
        print $"Error: ($error_msg)"
        return
    }

    let normalized_buffer_name = if ($buffer_name | str contains "~") {
        $buffer_name | path expand
    } else {
        $buffer_name
    }

    log_to_file "reveal_in_yazi.log" $"Normalized buffer name: '($normalized_buffer_name)'"

    let full_path = ($env.PWD | path join $normalized_buffer_name | path expand)
    log_to_file "reveal_in_yazi.log" $"Resolved full path: '($full_path)'"

    if not ($full_path | path exists) {
        let error_msg = $"Resolved path '($full_path)' does not exist."
        log_to_file "reveal_in_yazi.log" $"ERROR: ($error_msg)"
        print $"Error: ($error_msg)"
        return
    }

    if ($env.YAZI_ID | is-empty) {
        let error_msg = "YAZI_ID not set. reveal_in_yazi requires that you open helix from yazelix's yazi sidebar"
        log_to_file "reveal_in_yazi.log" $"ERROR: ($error_msg)"
        print $"Error: ($error_msg)"
        return
    }

    log_to_file "reveal_in_yazi.log" $"YAZI_ID found: '($env.YAZI_ID)'"

    try {
        # Use 'reveal' command instead of 'cd' to both navigate to directory and select the file
        ya emit-to $env.YAZI_ID reveal $full_path
        log_to_file "reveal_in_yazi.log" $"Successfully sent 'reveal ($full_path)' command to yazi instance ($env.YAZI_ID)"

        zellij action move-focus left
        log_to_file "reveal_in_yazi.log" "Successfully moved focus left to yazi pane"
    } catch {|err|
        let error_msg = $"Failed to execute yazi/zellij commands: ($err.msg)"
        log_to_file "reveal_in_yazi.log" $"ERROR: ($error_msg)"
        print $"Error: ($error_msg)"
    }
}


# Generic function to find and open file with editor integration
def open_with_editor_integration [
    file_path: path
    yazi_id: string
    editor_name: string
    log_file: string
    is_editor_running: closure
    open_in_existing: closure
    open_new_pane: closure
] {
    log_to_file $log_file $"open_with_($editor_name) called with file_path: '($file_path)'"

    # Move focus to editor pane (next pane from sidebar in layout order)
    # Layout order: sidebar → editor → aux, so focus-next-pane goes to editor
    zellij action focus-next-pane
    log_to_file $log_file "Moved focus to next pane (editor)"
    
    # Check if editor is already running in this pane
    let running_command = (get_running_command)
    log_to_file $log_file $"Running command in focused pane: ($running_command)"
    
    if (do $is_editor_running $running_command) {
        # Editor is running, open file in existing instance
        log_to_file $log_file $"($editor_name) already running, opening in existing instance"
        do $open_in_existing $file_path
    } else {
        # Editor not running (pane has shell), launch editor with file
        log_to_file $log_file $"($editor_name) not running, launching editor in current pane"
        do $open_new_pane $file_path $yazi_id
    }

    # Sync yazi's directory to match the opened file's location
    sync_yazi_to_directory $file_path $yazi_id $log_file

    log_to_file $log_file $"open_with_($editor_name) function completed"
}

# Open file with Helix (with full Yazelix integration)
def open_with_helix [file_path: path, yazi_id: string] {
    open_with_editor_integration $file_path $yazi_id "Helix" "open_helix.log" {|cmd| is_hx_running $cmd} {|path| open_in_existing_helix $path} {|path, id| open_new_helix_pane $path $id}
}

# Open file with Neovim (with full Yazelix integration)
def open_with_neovim [file_path: path, yazi_id: string] {
    open_with_editor_integration $file_path $yazi_id "Neovim" "open_neovim.log" {|cmd| is_nvim_running $cmd} {|path| open_in_existing_neovim $path} {|path, id| open_new_neovim_pane $path $id}
}

# Open file with generic editor (basic Zellij integration)
def open_with_generic_editor [file_path: path, editor: string, yazi_id: string] {
    log_to_file "open_generic.log" $"open_with_generic_editor called with file_path: '($file_path)', editor: '($editor)'"

    # Get the directory of the file for tab naming
    let file_dir = if ($file_path | path exists) and ($file_path | path type) == "dir" {
        $file_path
    } else {
        $file_path | path dirname
    }
    let tab_name = (get_tab_name $file_dir)

    try {
        # Create a new pane with the editor
        zellij action new-pane --cwd $file_dir -- $editor $file_path

        # Rename the tab
        zellij action rename-tab $tab_name

        log_to_file "open_generic.log" $"Successfully opened ($file_path) with ($editor) in new pane"
        print $"Opened ($file_path) with ($editor) in new pane"
    } catch {|err|
        let error_msg = $"Failed to open file with ($editor): ($err.msg)"
        log_to_file "open_generic.log" $"ERROR: ($error_msg)"
        print $"Error: ($error_msg)"
    }

    # Sync yazi's directory to match the opened file's location
    sync_yazi_to_directory $file_path $yazi_id "open_generic.log"

    log_to_file "open_generic.log" "open_with_generic_editor function completed"
}


# Main file opening function - dispatches to appropriate editor handler
export def open_file_with_editor [file_path: path] {
    log_to_file "open_editor.log" $"open_file_with_editor called with file_path: '($file_path)'"
    print $"DEBUG: file_path received: ($file_path), type: ($file_path | path type)"

    if not ($file_path | path exists) {
        let error_msg = $"File path ($file_path) does not exist"
        log_to_file "open_editor.log" $"ERROR: ($error_msg)"
        print $"Error: ($error_msg)"
        return
    }

    # Get the configured editor
    let editor = $env.EDITOR
    if ($editor | is-empty) {
        let error_msg = "EDITOR environment variable is not set"
        log_to_file "open_editor.log" $"ERROR: ($error_msg)"
        print $"Error: ($error_msg)"
        return
    }

    log_to_file "open_editor.log" $"Using editor: ($editor)"

    # Check if sidebar is enabled
    let sidebar_enabled = ($env.YAZELIX_ENABLE_SIDEBAR? | default "true") == "true"
    log_to_file "open_editor.log" $"Sidebar enabled: ($sidebar_enabled)"

    # Capture YAZI_ID from Yazi's pane
    let yazi_id = $env.YAZI_ID
    if ($yazi_id | is-empty) {
        let warning_msg = "YAZI_ID not set in this environment. Yazi navigation may fail."
        log_to_file "open_editor.log" $"WARNING: ($warning_msg)"
        print $"Warning: ($warning_msg)"
    } else {
        log_to_file "open_editor.log" $"YAZI_ID found: '($yazi_id)'"
    }

    # For no-sidebar mode, we still use the multi-pane approach since we start with editor
    # The native editor-Yazi integration (Ctrl+y) handles the "open in same pane" workflow

    # Dispatch to the appropriate editor handler
    if (is_helix_editor $editor) {
        log_to_file "open_editor.log" "Detected Helix editor, using Helix-specific logic"
        open_with_helix $file_path $yazi_id
    } else if (is_neovim_editor $editor) {
        log_to_file "open_editor.log" "Detected Neovim editor, using Neovim-specific logic"
        open_with_neovim $file_path $yazi_id
    } else {
        log_to_file "open_editor.log" $"Using generic editor approach for: ($editor)"
        open_with_generic_editor $file_path $editor $yazi_id
    }

    # Markdown preview disabled - files open in editor only
    # To re-enable: render_markdown_in_aux_pane $file_path

    log_to_file "open_editor.log" "open_file_with_editor function completed"
}
