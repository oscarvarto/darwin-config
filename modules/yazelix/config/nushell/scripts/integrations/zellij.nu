#!/usr/bin/env nu
# Zellij integration utilities for Yazelix

use ../utils/logging.nu *

# Get the tab name based on Git repo or working directory
export def get_tab_name [working_dir: path] {
    try {
        let git_root = (bash -c $"cd '($working_dir)' && git rev-parse --show-toplevel 2>/dev/null" | str trim)
        if ($git_root | is-not-empty) and (not ($git_root | str starts-with "fatal:")) {
            log_to_file "open_helix.log" $"Git root found: ($git_root)"
            $git_root | path basename
        } else {
            let basename = ($working_dir | str trim | path basename)
            log_to_file "open_helix.log" $"No valid Git repo, using basename of ($working_dir): ($basename)"
            if ($basename | is-empty) {
                "unnamed"
            } else {
                $basename
            }
        }
    } catch {
        $working_dir | path basename
    }
}

# Get the running command from the second Zellij client
export def get_running_command [] {
    try {
        let list_clients_output = (zellij action list-clients | lines | get 1)

        $list_clients_output
            | parse --regex '\w+\s+\w+\s+(?<rest>.*)'
            | get rest
            | to text
    } catch {
        ""
    }
}

# Check if Helix is running based on command string
export def is_hx_running [command: string] {
    ($command | str contains "hx") or ($command | str contains "helix")
}

def get_helix_command_key [] {
    let key = ($env.YAZELIX_HELIX_COMMAND_KEY? | default ":")
    if ($key | describe) == "string" and ($key | str trim | is-not-empty) {
        $key
    } else {
        ":"
    }
}

def helix_command [command: string] {
    let key = get_helix_command_key
    $"($key)($command)"
}

def apply_helix_theme [theme: string, log_file: string] {
    if ($theme | is-empty) {
        return
    }
    try {
        zellij action write 27
        let cmd = (helix_command $"theme ($theme)")
        zellij action write-chars $cmd
        zellij action write 13
        log_to_file $log_file $"Applied Helix theme: ($theme)"
    } catch {|err|
        log_to_file $log_file $"Failed to apply Helix theme: ($err.msg)"
    }
}

# Cycle through up to max_panes, looking for a Helix pane by name or running command
export def find_and_focus_helix_pane [max_panes: int = 3, helix_pane_name: string = "editor"] {
    mut i = 0
    while ($i < $max_panes) {
        let running_command = (get_running_command)
        let pane_name = (get_focused_pane_name)
        if (is_hx_running $running_command) or ($pane_name == $helix_pane_name) {
            return true
        }
        zellij action focus-next-pane
        $i = $i + 1
    }
    return false
}

# Helper to get the name of the currently focused pane (best effort)
export def get_focused_pane_name [] {
    # Zellij doesn't expose pane names directly via CLI
    # We use ZELLIJ_PANE_NAME env var if available in the pane
    try {
        let output = (zellij action list-clients | lines | get 1)
        # Example output: CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND
        # We try to parse the pane name from the ZELLIJ_PANE_ID if possible
        $output | split row " " | get 1 | to text
    } catch {
        ""
    }
}

# Focus the editor pane by moving right from sidebar
export def focus_editor_pane [] {
    # From sidebar, editor is one pane to the right
    # From aux, editor is one pane to the left
    # We'll move focus right from current position and check
    zellij action move-focus right
}

# Move the currently focused pane to the top of the stack by moving up 'steps' times
export def move_focused_pane_to_top [steps: int] {
    mut i = 0
    while ($i < $steps) {
        zellij action move-pane up
        $i = $i + 1
    }
}

# Generic function to open file in existing editor instance
def open_in_existing_editor [
    file_path: path
    cd_command: string
    open_command: string
    use_quotes: bool
    log_file: string
    editor_name: string
] {
    log_to_file $log_file $"Starting open_in_existing_($editor_name) with file_path: '($file_path)'"

    let working_dir = if ($file_path | path exists) and ($file_path | path type) == "dir" {
        $file_path
    } else {
        $file_path | path dirname
    }

    log_to_file $log_file $"Calculated working_dir: ($working_dir)"

    if not ($file_path | path exists) {
        log_to_file $log_file $"Error: File path ($file_path) does not exist"
        print $"Error: File path ($file_path) does not exist"
        return
    }

    log_to_file $log_file $"File path validated as existing"

    let tab_name = get_tab_name $working_dir
    log_to_file $log_file $"Calculated tab_name: ($tab_name)"

    try {
        zellij action write 27
        log_to_file $log_file "Sent Escape \(27\) to enter normal mode"

        let cd_cmd = if $use_quotes {
            $"($cd_command) \"($working_dir)\""
        } else {
            $"($cd_command) ($working_dir)"
        }
        zellij action write-chars $cd_cmd
        log_to_file $log_file $"Sent cd command: ($cd_cmd)"
        zellij action write 13
        log_to_file $log_file "Sent Enter \(13\) for cd command"

        let file_cmd = if $use_quotes {
            $"($open_command) \"($file_path)\""
        } else {
            $"($open_command) ($file_path)"
        }
        zellij action write-chars $file_cmd
        log_to_file $log_file $"Sent open command: ($file_cmd)"
        zellij action write 13
        log_to_file $log_file "Sent Enter \(13\) for open command"

        zellij action rename-tab $tab_name
        log_to_file $log_file $"Renamed tab to: ($tab_name)"

        # Note: Theme is only applied when launching a new Helix instance,
        # not when opening files in an existing one (to avoid race conditions
        # where the :theme command gets typed into the buffer)

        log_to_file $log_file "Commands executed successfully"
    } catch {|err|
        log_to_file $log_file $"Error executing commands: ($err.msg)"
        print $"Error executing commands: ($err.msg)"
    }
}

# Open a file in an existing Helix pane and rename tab
export def open_in_existing_helix [file_path: path] {
    open_in_existing_editor $file_path (helix_command "cd") (helix_command "open") true "open_helix.log" "helix"
}

# Generic function to open editor in the existing editor pane
# Note: This function assumes focus is ALREADY on the editor pane (called after focus-next-pane)
def open_new_editor_pane [file_path: path, yazi_id: string, log_file: string, helix_theme: string] {
    let working_dir = if ($file_path | path exists) and ($file_path | path type) == "dir" {
        $file_path
    } else {
        $file_path | path dirname
    }

    log_to_file $log_file $"Attempting to open file in editor pane with YAZI_ID=($yazi_id) for file=($file_path)"

    let tab_name = get_tab_name $working_dir
    log_to_file $log_file $"Calculated tab_name: ($tab_name)"

    # Use the configured editor from environment
    let editor = $env.EDITOR
    
    # Send the editor command to the current pane (which should be the editor pane with a shell)
    # Focus is already on editor pane from open_with_editor_integration
    # Use env to keep this shell-agnostic (works for nu, bash, zsh).
    let shell_name = ($env.SHELL? | default "unknown")
    let cmd = $"env YAZI_ID=($yazi_id) ($editor) '($file_path)'\r"
    log_to_file $log_file $"Editor pane env: SHELL=($shell_name) EDITOR=($editor) YAZI_ID=($yazi_id)"
    log_to_file $log_file $"Sending command to editor pane: ($cmd)"
    try {
        zellij action write-chars $cmd
        log_to_file $log_file "Command sent to editor pane successfully"
        if ($helix_theme | is-not-empty) {
            sleep 150ms
            apply_helix_theme $helix_theme $log_file
        }
    } catch {|err|
        let error_msg = $"Failed to send command to editor pane: ($err.msg)"
        log_to_file $log_file $"ERROR: ($error_msg)"
        print $"Error: ($error_msg)"
    }

    zellij action rename-tab $tab_name
    log_to_file $log_file $"Renamed tab to: ($tab_name)"
}

# Open a new pane and set up Helix with Yazi integration, renaming tab
export def open_new_helix_pane [file_path: path, yazi_id: string] {
    let helix_theme = ($env.YAZELIX_HELIX_THEME? | default "")
    open_new_editor_pane $file_path $yazi_id "open_helix.log" $helix_theme
}

# Neovim integration functions

# Check if Neovim is running
export def is_nvim_running [command: string] {
    ($command | str contains "nvim") or ($command | str contains "neovim")
}

# Open a file in an existing Neovim pane and rename tab
export def open_in_existing_neovim [file_path: path] {
    open_in_existing_editor $file_path ":cd" ":edit" false "open_neovim.log" "neovim"
}

# Open a new pane and set up Neovim with Yazi integration, renaming tab
export def open_new_neovim_pane [file_path: path, yazi_id: string] {
    open_new_editor_pane $file_path $yazi_id "open_neovim.log" ""
}
