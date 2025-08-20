#!/bin/bash

# Shell functions for darwin-config
# This file is sourced by shell-config.nix

# Yazi file manager function with directory change
# Usage: y [yazi-options] [directory]
function y() {
    local tmp cwd
    
    # Check if yazi is available
    if ! command -v yazi >/dev/null 2>&1; then
        echo "Error: yazi is not installed or not in PATH" >&2
        return 1
    fi
    
    # Create temporary file for cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    if [[ $? -ne 0 ]] || [[ -z "$tmp" ]]; then
        echo "Error: Failed to create temporary file" >&2
        return 1
    fi
    
    # Run yazi with cwd file
    yazi "$@" --cwd-file="$tmp"
    
    # Read the directory from the temp file
    if [[ -f "$tmp" ]]; then
        IFS= read -r -d '' cwd < "$tmp" || IFS= read -r cwd < "$tmp"
        
        # Change directory if it's different and exists
        if [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]] && [[ -d "$cwd" ]]; then
            builtin cd -- "$cwd"
        fi
    fi
    
    # Clean up temporary file
    rm -f -- "$tmp"
}
