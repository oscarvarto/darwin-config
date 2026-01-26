{
  config,
  pkgs,
  lib,
  user,
  ...
}: {
  home.activation = {
    # Clean up backup files to prevent collisions
    cleanupBackupFiles = lib.hm.dag.entryBefore ["checkFilesChanged"] ''
      # Remove any existing .bak files that would conflict with home-manager backup creation
      echo "🧹 Cleaning up old backup files to prevent home-manager collisions..."
      $DRY_RUN_CMD rm -f ~/.config/starship.toml.bak
      $DRY_RUN_CMD rm -f ~/.config/zellij/config.kdl.bak
      # Also clean up any other .bak files in common config directories
      $DRY_RUN_CMD find ~/.config -name "*.bak" -type f -delete 2>/dev/null || true
      echo "✅ Backup file cleanup completed"
    '';

    # Install terminfo for Ghostty and Kitty terminals
    installTerminfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "🖥️  Installing terminal terminfo definitions..."

      # Create ~/.terminfo directory if it doesn't exist
      $DRY_RUN_CMD mkdir -p ~/.terminfo

      # Install Ghostty terminfo if app exists
      if [[ -d /Applications/Ghostty.app ]]; then
        GHOSTTY_TERMINFO="/Applications/Ghostty.app/Contents/Resources/terminfo"
        if [[ -d "$GHOSTTY_TERMINFO" ]]; then
          echo "  📦 Installing Ghostty terminfo from app bundle..."
          # Copy the compiled terminfo directly (Ghostty ships pre-compiled terminfo)
          $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -av "$GHOSTTY_TERMINFO/" ~/.terminfo/
          echo "  ✅ Ghostty terminfo installed"
        fi
      fi

      # Install Kitty terminfo if app exists and has source terminfo
      if [[ -d /Applications/kitty.app ]]; then
        KITTY_TERMINFO_SRC="/Applications/kitty.app/Contents/Resources/kitty/terminfo/kitty.terminfo"
        if [[ -f "$KITTY_TERMINFO_SRC" ]]; then
          echo "  📦 Installing Kitty terminfo from source..."
          # Compile and install using tic
          $DRY_RUN_CMD ${pkgs.ncurses}/bin/tic -x -o ~/.terminfo "$KITTY_TERMINFO_SRC"
          echo "  ✅ Kitty terminfo installed"
        fi
      fi

      echo "✅ Terminal terminfo installation completed"
    '';

    ensureTabbyAgentConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
            tabby_agent_dir="$HOME/.tabby-client/agent"
            tabby_agent_config="$tabby_agent_dir/config.toml"

            $DRY_RUN_CMD mkdir -p "$tabby_agent_dir"

            if [[ ! -f "$tabby_agent_config" ]]; then
              echo "🤖 Creating Tabby Agent config template at $tabby_agent_config"
              $DRY_RUN_CMD cat > "$tabby_agent_config" <<'EOF'
      [server]
      endpoint = "http://127.0.0.1:8080"

      # Paste the auth token shown in the Tabby web UI (http://127.0.0.1:8080/) here:
      # token = "your-token-here"
      EOF
              echo "✅ Tabby Agent config template created (add token to enable Helix completions)"
            fi
    '';

    ensureHelixGptCopilotKeyFile = lib.hm.dag.entryAfter ["writeBoundary"] ''
            helix_gpt_dir="$HOME/.config/helix-gpt"
            copilot_key_file="$helix_gpt_dir/copilot_api_key"

            $DRY_RUN_CMD mkdir -p "$helix_gpt_dir"

            if [[ ! -f "$copilot_key_file" ]]; then
              echo "🤖 Creating helix-gpt Copilot token file at $copilot_key_file"
              $DRY_RUN_CMD cat > "$copilot_key_file" <<'EOF'
      # Paste your Copilot token here (from `helix-gpt --authCopilot`).
      # You can either paste the raw token, or use: COPILOT_API_KEY="..."
      EOF
              echo "✅ helix-gpt token file created"
            fi
    '';
  };
}
