{ pkgs, config, ... }:

let
  # Get user from the nixos-config function to avoid absolute paths
  user = config.users.users.oscarvarto.name or "oscarvarto";
in
{
  
  # NOTE: Nix cleanup scripts are now managed via stow (nix-scripts package)
  # Run: cd ~/nixos-config/stow && stow nix-scripts

  # Ghostty base configuration (managed by Nix)
  ".config/ghostty/config" = {
    text = ''
      # Ghostty Configuration - Base settings managed by Nix
      # Override settings in ~/.config/ghostty/overrides.conf for quick changes
 
      # Shell configuration (default fish, can be overridden)
      # Note: Default shell is set below, override with ghostty-config shell <shell-name>
      shell-integration = fish
      shell-integration-features = cursor,sudo,title

      # Default font (can be overridden)
      # font-family = PragmataPro Mono Liga
      font-family = MonoLisaVariable Nerd Font
      font-size = 18
 
      # Default theme (can be overridden)
      theme = dracula

      # Default shell (can be overridden)
      command = /Users/${user}/.nix-profile/bin/fish -i -l
      initial-command = /Users/${user}/.nix-profile/bin/fish -i -l

      # Window and appearance settings
      split-divider-color = green
      window-save-state = always
      cursor-style = block
      cursor-color = "#D9905A"
      auto-update-channel = tip
      quit-after-last-window-closed = true

      # macOS specific settings
      macos-option-as-alt = left

      # Key bindings
      keybind = global:super+ctrl+grave_accent=toggle_quick_terminal

      # Include user overrides LAST so they take precedence
      config-file = ~/.config/ghostty/overrides.conf
    '';
  };

  # Note: overrides.conf is NOT managed by Nix - it's created and managed by the helper scripts
  # This allows users to edit it directly without rebuilding the Nix configuration

  # NOTE: Ghostty configuration scripts are now managed via stow (nix-scripts package)
  # Run: cd ~/nixos-config/stow && stow nix-scripts

  # Zellij configuration
  ".config/zellij/config.kdl" = {
    text = builtins.replaceStrings 
      ["default_shell \"fish\""]
      ["default_shell \"/Users/${user}/.local/share/bin/zellij-shell-wrapper\""]
      (builtins.readFile ../darwin/zellij-config.kdl);
  };

  # Shell wrapper script for zellij to detect current shell
  ".local/share/bin/zellij-shell-wrapper" = {
    text = ''#!/bin/bash
      # Zellij shell wrapper - detects and launches appropriate shell
      
      # Function to get the current shell name from process tree
      get_current_shell() {
        # Check if we're being called as an explicit shell command
        # Look at the immediate parent process to see if it's a shell invocation
        local immediate_parent_cmd=$(ps -p $PPID -o args= 2>/dev/null)
        
        # If parent is explicitly calling a specific shell, respect that
        case "$immediate_parent_cmd" in
          *fish*|*/fish)
            echo "fish"
            return
            ;;
          *nu*|*/nu|*nushell*)
            echo "nushell"
            return
            ;;
          *zsh*|*/zsh)
            echo "zsh"
            return
            ;;
          *bash*|*/bash)
            echo "bash"
            return
            ;;
        esac
        
        # Only check environment variables if not explicitly invoked
        if [ -n "$NU_VERSION" ]; then
          echo "nushell"
          return
        fi
        
        local parent_pid=$PPID
        local depth=0
        
        while [ $parent_pid -ne 1 ] && [ $depth -lt 15 ]; do
          local cmd=$(ps -p $parent_pid -o comm= 2>/dev/null | xargs basename 2>/dev/null)
          local full_cmd=$(ps -p $parent_pid -o args= 2>/dev/null)
          
          case "$cmd" in
            fish)
              echo "fish"
              return
              ;;
            nu)
              echo "nushell"
              return
              ;;
            nushell)
              echo "nushell"
              return
              ;;
            zsh)
              echo "zsh"
              return
              ;;
            bash)
              echo "bash"
              return
              ;;
          esac
          
          # Also check if the full command line contains our shells
          case "$full_cmd" in
            */nu*|*nushell*)
              echo "nushell"
              return
              ;;
            */fish*)
              echo "fish"
              return
              ;;
          esac
          
          parent_pid=$(ps -p $parent_pid -o ppid= 2>/dev/null | tr -d ' ')
          [ -z "$parent_pid" ] && break
          depth=$((depth + 1))
        done
        
        # Additional fallback: check if nu is in PATH and we couldn't detect the shell
        if command -v nu >/dev/null 2>&1; then
          # Check if any parent process might be nu by looking at all processes
          local current_pid=$$
          while [ $current_pid -ne 1 ]; do
            local parent_info=$(ps -p $current_pid -o ppid=,comm= 2>/dev/null)
            if echo "$parent_info" | grep -q "nu"; then
              echo "nushell"
              return
            fi
            current_pid=$(echo "$parent_info" | awk '{print $1}' | tr -d ' ')
            [ -z "$current_pid" ] && break
          done
        fi
        
        echo "fish" # fallback to fish
      }
      
      # Detect current shell
      DETECTED_SHELL=$(get_current_shell)
      
      # Launch appropriate nix-profile shell
      case "$DETECTED_SHELL" in
        "nushell")
          if [ -x "/Users/${user}/.nix-profile/bin/nu" ]; then
            exec "/Users/${user}/.nix-profile/bin/nu" "$@"
          else
            exec "/Users/${user}/.nix-profile/bin/fish" "$@"
          fi
          ;;
        "fish")
          exec "/Users/${user}/.nix-profile/bin/fish" "$@"
          ;;
        "zsh")
          if [ -x "/Users/${user}/.nix-profile/bin/zsh" ]; then
            exec "/Users/${user}/.nix-profile/bin/zsh" "$@"
          else
            exec "/Users/${user}/.nix-profile/bin/fish" "$@"
          fi
          ;;
        "bash")
          if [ -x "/Users/${user}/.nix-profile/bin/bash" ]; then
            exec "/Users/${user}/.nix-profile/bin/bash" "$@"
          else
            exec "/Users/${user}/.nix-profile/bin/fish" "$@"
          fi
          ;;
        *)
          # Default fallback to fish
          exec "/Users/${user}/.nix-profile/bin/fish" "$@"
          ;;
      esac
    '';
    executable = true;
  };
}

