#!/usr/bin/env nu
# Render markdown previews using the piper previewer command from yazi.toml.

use ../utils/constants.nu [YAZI_CONFIG_PATHS]
use ../utils/logging.nu log_to_file

def get_previewers [config: record] {
    let plugin = ($config.plugin? | default {})
    let prepend = ($plugin.prepend_previewers? | default [])
    let append = ($plugin.append_previewers? | default [])
    $prepend | append $append
}

def find_markdown_previewer [previewers: list] {
    let matches = (
        $previewers
            | where {|entry|
                let url = ($entry.url? | default "")
                let name = ($entry.name? | default "")
                let mime = ($entry.mime? | default "")
                ($url == "*.md") or ($name == "*.md") or ($mime == "text/markdown") or ($mime == "text/*")
            }
    )
    if ($matches | is-empty) {
        ""
    } else {
        $matches | get run | first
    }
}

def strip_piper_prefix [run_cmd: string] {
    let trimmed = ($run_cmd | str trim)
    $trimmed | str replace -r '^\s*piper\s+--\s+' ''
}

def resolve_glow [cmd: string] {
    mut result = $cmd
    # Use GLOW_BIN if glow not in PATH
    if ($cmd | str contains "glow") and (which glow | is-empty) and ($env.GLOW_BIN? | is-not-empty) {
        $result = ($result | str replace -r '\\bglow\\b' $env.GLOW_BIN)
    }
    # Add -p flag for pager mode if not already present
    if ($result | str contains "glow") and not ($result | str contains " -p") {
        $result = ($result | str replace "glow " "glow -p ")
    }
    $result
}

def main [file_path: path] {
    let config_path = ($YAZI_CONFIG_PATHS.merged_config_dir | path expand | path join "yazi.toml")
    let config = try { open $config_path } catch {
        log_to_file "md_preview.log" $"Failed to read yazi.toml at ($config_path)"
        return
    }

    let previewers = get_previewers $config
    let run_cmd = find_markdown_previewer $previewers
    if ($run_cmd | is-empty) {
        log_to_file "md_preview.log" "No markdown previewer found in yazi.toml"
        return
    }

    let base_cmd = resolve_glow (strip_piper_prefix $run_cmd)
    let final_cmd = if ($base_cmd | str contains "glow") and (which glow | is-empty) and ($env.GLOW_BIN? | is-empty) {
        log_to_file "md_preview.log" "glow not found for preview, falling back to cat"
        'cat "$1"'
    } else {
        $base_cmd
    }
    log_to_file "md_preview.log" $"Running preview command: ($final_cmd)"

    let size = term size
    let width = ($size.columns | default 80)
    let height = ($size.rows | default 24)

    with-env {w: $width, h: $height} {
        ^sh -c $final_cmd "sh" $file_path
    }
}
