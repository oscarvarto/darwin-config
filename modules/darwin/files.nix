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
 
      # Shell configuration (default nushell, can be overridden)
      # Note: Default shell is set below, override with ghostty-config shell <shell-name>
      shell-integration = none
      shell-integration-features = cursor,sudo,title

      # Default font (can be overridden)
      # font-family = PragmataPro Mono Liga
      font-family = MonoLisaVariable Nerd Font
      font-size = 18
 
      # Default theme (can be overridden)
      theme = dracula

      # Default shell (can be overridden)
      command = /Users/${user}/.nix-profile/bin/nu -i -l
      initial-command = /Users/${user}/.nix-profile/bin/nu -i -l

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
    text = builtins.readFile ./zellij-config.kdl;
  };

}

