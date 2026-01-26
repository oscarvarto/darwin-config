{
  pkgs,
  config,
  user ? "oscarvarto",
  ...
}: let
  # User is passed as parameter or falls back to default
  homeDir =
    if config ? users.users.${user}.home
    then config.users.users.${user}.home
    else "/Users/${user}";
  xdg_configHome = "${homeDir}/.config";
in {
  # NOTE: Nix cleanup scripts are now managed via stow (nix-scripts package)
  # Run: cd ~/darwin-config/stow && stow nix-scripts

  # Create a template config file with biometric settings for all 1Password vaults
  "${xdg_configHome}/op/biometric-config.json" = {
    text = ''
      {
        "app_start": {
          "biometric_unlock": true,
          "biometric_unlock_timeout": 86400
        },
        "account": {
          "biometric_unlock": true
        },
        "vaults": {
          "Personal": {
            "biometric_unlock": true
          },
          "Work": {
            "biometric_unlock": true
          }
        }
      }
    '';

    # Use onChange to merge the configurations
    onChange = ''
      # Ensure the op config directory exists
      mkdir -p "$HOME/.config/op"

      if [ -f "$HOME/.config/op/config" ]; then
        # Create a temporary file for the merged config
        TEMP_FILE=$(mktemp)

        # Use jq to merge the existing config with the biometric settings
        jq -s '.[0] * .[1]' "$HOME/.config/op/config" "$HOME/.config/op/biometric-config.json" > "$TEMP_FILE"

        # Replace the config file with the merged version
        mv "$TEMP_FILE" "$HOME/.config/op/config"
      else
        # If no config exists yet, just copy the biometric config
        cp "$HOME/.config/op/biometric-config.json" "$HOME/.config/op/config"
      fi

      # Set proper permissions for 1Password CLI security requirements
      chmod 600 "$HOME/.config/op/config"
    '';
  };

  # Ghostty base configuration (managed by Nix)
  ".config/ghostty/config" = {
    text = ''
      # Ghostty Configuration - Base settings managed by Nix

      # Optional runtime overrides (managed by ghostty-config)
      config-file = ?overrides.conf

      # Shell configuration (default nushell, can be overridden)
      # Note: Default shell is set below, override with ghostty-config shell <shell-name>
      # Enable shell integration for proper cursor handling in Zellij/Nushell
      shell-integration = detect
      shell-integration-features = cursor,sudo,title

      # Default font with fallbacks (can be overridden)
      # font-family = PragmataPro Mono Liga
      font-family = MonoLisaVariable Nerd Font, PragmataPro Mono Liga, JetBrains Mono, SF Mono, monospace
      font-size = 18
      font-thicken = true
      font-thicken-strength = 200
      alpha-blending = native
      background-opacity = 0.9
      scrollback-limit = 900000000

      # Default theme (can be overridden)
      theme = Catppuccin Latte

      # Default shell (can be overridden)
      initial-command = /Users/${user}/.nix-profile/bin/nu --login --interactive
      command = /Users/${user}/.nix-profile/bin/nu --login --interactive
      term = xterm-ghostty
      mouse-shift-capture = always
      cursor-click-to-move = false
      focus-follows-mouse = false

      # Window and appearance settings
      window-save-state = always
      cursor-style = block
      cursor-color = "#D9905A"
      auto-update-channel = tip
      quit-after-last-window-closed = true

      # macOS specific settings
      macos-option-as-alt = left

      # Key bindings
      keybind = global:super+ctrl+grave_accent=toggle_quick_terminal
      # Claude Code terminal integration - Shift+Enter to submit prompt
      keybind = shift+enter=text:\x1b[13;2u
    '';
  };

  # [NOTE] overrides.conf is NOT managed by Nix - it's created and managed by the helper scripts
  # This allows users to edit it directly without rebuilding the Nix configuration

  # 1Password SSH agent setup helper script
  ".local/share/bin/setup-1password-ssh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      # 1Password SSH Agent Setup Helper
      # This script helps you enable 1Password SSH agent integration

      set -e

      echo "🔐 1Password SSH Agent Setup"
      echo "=============================="
      echo ""
      echo "To enable biometric SSH authentication with 1Password:"
      echo ""
      echo "1. Open 1Password app"
      echo "2. Go to Settings/Preferences → Developer"
      echo "3. Enable 'Use the SSH agent'"
      echo "4. Optionally enable 'Display key names when authorizing connections'"
      echo ""
      echo "5. Then uncomment the IdentityAgent line in your SSH config:"
      echo "   Edit ~/.ssh/config and uncomment:"
      echo "   # Host *"
      echo "   #     IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
      echo ""
      echo "6. Test SSH agent:"
      echo "   ssh-add -l"
      echo ""
      echo "Your 1Password vaults configured for biometric auth:"
      echo "• Personal vault: Biometric unlock enabled"
      echo "• Work vault: Biometric unlock enabled"
      echo ""
      echo "Once configured, you can use Touch ID for:"
      echo "• SSH authentication"
      echo "• sudo commands (already configured)"
      echo "• 1Password CLI operations"
    '';
  };

  # NOTE: Ghostty configuration scripts are now managed via stow (nix-scripts package)
  # Run: cd ~/darwin-config/stow && stow nix-scripts

  # Zellij configuration with custom keybindings - theme managed by Nix Catppuccin
  ".config/zellij/config.kdl" = {
    source = ./zellij-config.kdl;
  };
}
