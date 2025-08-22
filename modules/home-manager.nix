{ config, pkgs, user, hostname, hostSettings, defaultShell ? "zsh", pathConfig ? null, ... } @ inputs:

let
  sharedFiles = import ./files.nix { inherit config pkgs user; };
  inherit (builtins) fromTOML;
  
  # User configuration based on hostSettings  
  userConfig = {
    # Use secure fallback names - actual credentials will be retrieved dynamically
    name = if hostSettings.enablePersonalConfig then user else user;
    email = if hostSettings.enablePersonalConfig then "${user}@users.noreply.github.com" else "${user}@company.com";
    workDir = if hostSettings.workProfile then "work" else "dev";
  };
  
  # Work configuration - extract pattern without '/**' suffix for directory name
  workConfig = hostSettings.workConfig or {};
  workDirName = builtins.replaceStrings ["~/" "/**"] ["" ""] (workConfig.gitWorkDirPattern or "~/work/**");
in
{

  imports = [
    ./dock
    ./brews.nix
    ./window-manager.nix
    ./zsh-darwin.nix
  ];

  # User configuration is now handled in system.nix based on defaultShell

  environment.variables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    BAT_THEME="ansi";
    # Force Enchant to use aspell and point aspell to the Nix-provided dictionaries
    ENCHANT_ORDERING = "en:aspell,es:aspell,*:aspell";
    ASPELL_CONF = "dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell";
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs; };
    users.${user} = { pkgs, config, lib, ... }: {
      imports = [
        ./git-security-scripts.nix
        inputs.catppuccin.homeModules.catppuccin
        inputs.op-shell-plugins.hmModules.default
      ] ++ [ ./nushell ]; # Always include nushell module for starship integration
      # Fish configuration is handled inline in programs.fish below
      # No separate fish module needed

      # Test: re-enable font management now that mise SDK issues are fixed
      # disabledModules = [ "targets/darwin/fonts.nix" ];

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = (pkgs.callPackage ./packages.nix {}) ++ [
          # Add neovim-nightly from overlay
          inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim
          # Add nixd nightly from flake input
          inputs.nixd-ls.packages.${pkgs.stdenv.hostPlatform.system}.default
          # Note: Ghostty from official flake currently fails to build on macOS ARM due to Darwin SDK issues
          # Using homebrew cask version instead until build issues are resolved
          # inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
        file = sharedFiles // {
          
          # Automatic theme switcher script
          ".local/bin/catppuccin-theme-switcher" = {
            executable = true;
            text = ''
              #!/usr/bin/env bash
              
              # Catppuccin Theme Switcher
              # Automatically switches themes across all supported applications
              
              VERSION="1.2.0"
              
              show_help() {
                  cat << 'HELP_EOF'
              🎨 Catppuccin Theme Switcher v$VERSION
              
              A unified theme switcher that synchronizes Catppuccin themes across all your applications
              based on macOS system appearance or manual selection.
              
              USAGE:
                  catppuccin-theme-switcher [OPTIONS]
              
              OPTIONS:
                  -h, --help          Show this help message
                  -v, --version       Show version information
                  -s, --status        Show current theme status across all applications
                  -f, --force-light   Force light theme (Catppuccin Latte) regardless of system setting
                  -d, --force-dark    Force dark theme (Catppuccin Mocha) regardless of system setting
                  -a, --auto          Use automatic system appearance detection (default)
                  -q, --quiet         Run silently without output
                  --dry-run          Show what would be changed without making changes
              
              SUPPORTED APPLICATIONS:
                  • Starship (shell prompt)
                  • Atuin (shell history)
                  • Zellij (terminal multiplexer)
                  • Ghostty (terminal emulator) - Live config reload without restart
                  • Nushell (shell syntax highlighting)
                  • Fish (shell colors)
                  • Zsh (shell colors)
                  • BAT (syntax highlighter)
              
              THEME MAPPING:
                  Light Mode:  Catppuccin Latte (with high contrast colors)
                  Dark Mode:   Catppuccin Mocha (with vibrant colors)
              
              AUTOMATIC MODE:
                  The script automatically detects macOS system appearance:
                  • System Light Mode → Catppuccin Latte
                  • System Dark Mode  → Catppuccin Mocha
              
              EXAMPLES:
                  catppuccin-theme-switcher              # Auto-detect and apply theme
                  catppuccin-theme-switcher --status     # Show current theme status
                  catppuccin-theme-switcher --force-dark # Force dark theme
                  catppuccin-theme-switcher --force-light --quiet # Force light theme silently
                  catppuccin-theme-switcher --dry-run    # Preview changes
              
              INTEGRATION:
                  This script runs automatically when macOS appearance changes via LaunchAgent.
                  Manual theme switching functions are also available:
                  • catppuccin-theme-switch (alias)
                  • ghostty-theme-light.nu / ghostty-theme-dark.nu (Ghostty-specific)
              
              FILES:
                  ~/.cache/nushell_theme    Theme cache for Nushell
                  ~/.cache/fish_theme       Theme cache for Fish
                  ~/.cache/zsh_theme        Theme cache for Zsh
              
              EXIT CODES:
                  0    Success
                  1    Error in theme switching
                  2    Invalid command line arguments
              
HELP_EOF
              }
              
              show_version() {
                  echo "Catppuccin Theme Switcher v$VERSION"
                  echo "Unified theme management for macOS development environment"
              }
              
              show_status() {
                  echo "🔍 Current Theme Status:"
                  echo ""
                  
                  # System appearance
                  if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q "Dark"; then
                      echo "🖥️  System Appearance: Dark"
                  else
                      echo "🖥️  System Appearance: Light"
                  fi
                  
                  # Theme cache files
                  echo "📁 Theme Cache Files:"
                  for cache_file in ~/.cache/nushell_theme ~/.cache/fish_theme ~/.cache/zsh_theme; do
                      if [[ -f "$cache_file" ]]; then
                          theme=$(cat "$cache_file" 2>/dev/null || echo "unknown")
                          echo "   $(basename "$cache_file"): $theme"
                      else
                          echo "   $(basename "$cache_file"): not set"
                      fi
                  done
                  
                  # Application-specific themes
                  echo ""
                  echo "🎨 Application Themes:"
                  
                  # Starship
                  if [[ -f "$HOME/.config/starship.toml" ]]; then
                      starship_theme=$(grep "^palette = " "$HOME/.config/starship.toml" | sed "s/palette = '\(.*\)'/\1/" || echo "unknown")
                      echo "   Starship: $starship_theme"
                  else
                      echo "   Starship: not configured"
                  fi
                  
                  # Atuin
                  if [[ -f "$HOME/.config/atuin/config.toml" ]]; then
                      atuin_theme=$(grep 'name = ' "$HOME/.config/atuin/config.toml" | sed 's/name = "\(.*\)"/\1/' || echo "unknown")
                      echo "   Atuin: $atuin_theme"
                  else
                      echo "   Atuin: not configured"
                  fi
                  
                  # Zellij
                  if [[ -f "$HOME/.config/zellij/config.kdl" ]]; then
                      zellij_theme=$(grep 'theme "' "$HOME/.config/zellij/config.kdl" | sed 's/theme "\(.*\)"/\1/' || echo "unknown")
                      echo "   Zellij: $zellij_theme"
                  else
                      echo "   Zellij: not configured"
                  fi
                  
                  # Ghostty
                  if [[ -f "$HOME/.config/ghostty/overrides.conf" ]]; then
                      ghostty_theme=$(grep '^theme = ' "$HOME/.config/ghostty/overrides.conf" | sed 's/theme = \(.*\)/\1/' || echo "unknown")
                      echo "   Ghostty: $ghostty_theme"
                  else
                      echo "   Ghostty: not configured"
                  fi
                  
                  echo ""
              }
              
              # Parse command line arguments
              FORCE_THEME=""
              QUIET=false
              DRY_RUN=false
              
              while [[ $# -gt 0 ]]; do
                  case $1 in
                      -h|--help)
                          show_help
                          exit 0
                          ;;
                      -v|--version)
                          show_version
                          exit 0
                          ;;
                      -s|--status)
                          show_status
                          exit 0
                          ;;
                      -f|--force-light)
                          FORCE_THEME="light"
                          shift
                          ;;
                      -d|--force-dark)
                          FORCE_THEME="dark"
                          shift
                          ;;
                      -a|--auto)
                          FORCE_THEME=""
                          shift
                          ;;
                      -q|--quiet)
                          QUIET=true
                          shift
                          ;;
                      --dry-run)
                          DRY_RUN=true
                          shift
                          ;;
                      -*)
                          echo "Error: Unknown option $1" >&2
                          echo "Use --help for usage information" >&2
                          exit 2
                          ;;
                      *)
                          echo "Error: Unexpected argument $1" >&2
                          echo "Use --help for usage information" >&2
                          exit 2
                          ;;
                  esac
              done
              
              # Check for manual override file
              MANUAL_OVERRIDE_FILE="$HOME/.cache/catppuccin_manual_override"
              MANUAL_OVERRIDE=""
              if [[ -f "$MANUAL_OVERRIDE_FILE" ]]; then
                  MANUAL_OVERRIDE=$(cat "$MANUAL_OVERRIDE_FILE" 2>/dev/null | head -n1 | tr -d '\n')
              fi
              
              # Output function that respects quiet mode
              log() {
                  if [[ "$QUIET" != "true" ]]; then
                      echo "$@"
                  fi
              }
              
              # Store original arguments as string to work around Nix string interpolation
              ORIGINAL_ARGS="$*"
              
              # Check if --auto was used to clear override first
              if [[ "$ORIGINAL_ARGS" == *"--auto"* ]] || [[ "$ORIGINAL_ARGS" == *"-a"* ]]; then
                  rm -f "$MANUAL_OVERRIDE_FILE" 2>/dev/null
                  log "🔄 Cleared manual override - back to automatic mode"
                  MANUAL_OVERRIDE=""  # Clear override so it won't be used
              fi
              
              # Determine theme based on priority: CLI args > manual override > system appearance
              if [[ -n "$FORCE_THEME" ]]; then
                  APPEARANCE="$FORCE_THEME"
                  # If this is a manual force, save it as override (but not for --auto)
                  if [[ "$FORCE_THEME" == "light" && "$ORIGINAL_ARGS" != *"--auto"* && "$ORIGINAL_ARGS" != *"-a"* ]]; then
                      echo "light" > "$MANUAL_OVERRIDE_FILE"
                      log "💾 Saved light theme as manual override"
                  elif [[ "$FORCE_THEME" == "dark" && "$ORIGINAL_ARGS" != *"--auto"* && "$ORIGINAL_ARGS" != *"-a"* ]]; then
                      echo "dark" > "$MANUAL_OVERRIDE_FILE"
                      log "💾 Saved dark theme as manual override"
                  fi
              elif [[ -n "$MANUAL_OVERRIDE" && ("$MANUAL_OVERRIDE" == "light" || "$MANUAL_OVERRIDE" == "dark") ]]; then
                  APPEARANCE="$MANUAL_OVERRIDE"
                  log "🔒 Using manual override: $MANUAL_OVERRIDE mode"
              elif defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q "Dark"; then
                  APPEARANCE="dark"
              else
                  APPEARANCE="light"
              fi
              
              # Set theme variables
              if [[ "$APPEARANCE" == "dark" ]]; then
                  CATPPUCCIN_FLAVOR="mocha"
                  STARSHIP_PALETTE="catppuccin_mocha"
                  BAT_THEME="ansi"
              else
                  CATPPUCCIN_FLAVOR="latte"
                  STARSHIP_PALETTE="catppuccin_latte"
                  BAT_THEME="GitHub"
              fi
              
              # Dry run prefix
              if [[ "$DRY_RUN" == "true" ]]; then
                  log "🔍 DRY RUN MODE - No changes will be made"
                  log ""
              fi
              
              log "🎨 Catppuccin Theme Switcher"
              if [[ -n "$FORCE_THEME" ]]; then
                  log "🔧 Mode: Forced $APPEARANCE mode"
              else
                  log "🔧 Mode: Auto-detect (system appearance: $APPEARANCE)"
              fi
              log "🎨 Catppuccin flavor: $CATPPUCCIN_FLAVOR"
              log ""
              
              # Update starship configuration
              log "⭐ Updating Starship prompt theme..."
              STARSHIP_CONFIG="$HOME/.config/starship.toml"
              if [[ -f "$STARSHIP_CONFIG" ]]; then
                  if grep -q "^palette = " "$STARSHIP_CONFIG"; then
                      if [[ "$DRY_RUN" != "true" ]]; then
                          sed -i "" "s/^palette = .*/palette = '$STARSHIP_PALETTE'/" "$STARSHIP_CONFIG"
                      fi
                      log "   ✅ Updated Starship to use $STARSHIP_PALETTE"
                  else
                      log "   ⚠️  Starship palette setting not found in $STARSHIP_CONFIG"
                  fi
              else
                  log "   ❌ Starship config file not found: $STARSHIP_CONFIG"
              fi
              
              # Update atuin theme via environment variables (Nix-managed configs are read-only)
              log "📖 Updating Atuin history theme..."
              ATUIN_OVERRIDE="$HOME/.config/atuin/overrides.toml"
              if [[ "$DRY_RUN" != "true" ]]; then
                  mkdir -p "$(dirname "$ATUIN_OVERRIDE")"
                  if [[ "$APPEARANCE" == "light" ]]; then
                      cat > "$ATUIN_OVERRIDE" << 'ATUIN_EOF'
# Atuin theme overrides - managed by catppuccin-theme-switcher
# This file overrides Nix-managed configuration

[theme]
name = "catppuccin-latte-mauve"
ATUIN_EOF
                      log "   ✅ Created Atuin override for light theme (catppuccin-latte-mauve)"
                  else
                      cat > "$ATUIN_OVERRIDE" << 'ATUIN_EOF'
# Atuin theme overrides - managed by catppuccin-theme-switcher
# This file overrides Nix-managed configuration

[theme]
name = "catppuccin-mocha-mauve"
ATUIN_EOF
                      log "   ✅ Created Atuin override for dark theme (catppuccin-mocha-mauve)"
                  fi
              else
                  log "   🔍 Would create Atuin override for $APPEARANCE theme"
              fi
              
              # Update zellij theme
              log "🖼️  Updating Zellij multiplexer theme..."
              ZELLIJ_CONFIG="$HOME/.config/zellij/config.kdl"
              if [[ -f "$ZELLIJ_CONFIG" ]]; then
                  if [[ "$APPEARANCE" == "light" ]]; then
                      if grep -q 'theme "catppuccin-mocha"' "$ZELLIJ_CONFIG"; then
                          if [[ "$DRY_RUN" != "true" ]]; then
                              sed -i "" 's/theme "catppuccin-mocha"/theme "catppuccin-latte"/' "$ZELLIJ_CONFIG"
                          fi
                          log "   ✅ Updated zellij theme to light mode (catppuccin-latte)"
                      else
                          log "   ⚠️  Zellij mocha theme not found to replace"
                      fi
                  else
                      if grep -q 'theme "catppuccin-latte"' "$ZELLIJ_CONFIG"; then
                          if [[ "$DRY_RUN" != "true" ]]; then
                              sed -i "" 's/theme "catppuccin-latte"/theme "catppuccin-mocha"/' "$ZELLIJ_CONFIG"
                          fi
                          log "   ✅ Updated zellij theme to dark mode (catppuccin-mocha)"
                      else
                          log "   ⚠️  Zellij latte theme not found to replace"
                      fi
                  fi
              else
                  log "   ❌ Zellij config file not found: $ZELLIJ_CONFIG"
              fi
              
              # Update Ghostty theme
              log "👻 Updating Ghostty terminal theme..."
              GHOSTTY_OVERRIDES="$HOME/.config/ghostty/overrides.conf"
              if [[ -f "$GHOSTTY_OVERRIDES" ]]; then
                  if [[ "$APPEARANCE" == "light" ]]; then
                      # Switch from dark themes to catppuccin-latte or light fallback
                      if grep -q 'theme = dracula\|theme = catppuccin-mocha' "$GHOSTTY_OVERRIDES"; then
                          if [[ "$DRY_RUN" != "true" ]]; then
                              sed -i "" 's/theme = dracula/theme = catppuccin-latte/' "$GHOSTTY_OVERRIDES"
                              sed -i "" 's/theme = catppuccin-mocha/theme = catppuccin-latte/' "$GHOSTTY_OVERRIDES"
                          fi
                          log "   ✅ Updated Ghostty theme to catppuccin-latte (light mode)"
                      elif ! grep -q 'theme = catppuccin-latte\|theme = BlulocoLight' "$GHOSTTY_OVERRIDES"; then
                          # Add light theme if no theme is set
                          if [[ "$DRY_RUN" != "true" ]]; then
                              echo "theme = catppuccin-latte" >> "$GHOSTTY_OVERRIDES"
                          fi
                          log "   ✅ Added Ghostty theme catppuccin-latte (light mode)"
                      else
                          log "   ✅ Ghostty already using a light theme"
                      fi
                  else
                      # Switch from light themes to catppuccin-mocha or dark fallback
                      if grep -q 'theme = BlulocoLight\|theme = catppuccin-latte' "$GHOSTTY_OVERRIDES"; then
                          if [[ "$DRY_RUN" != "true" ]]; then
                              sed -i "" 's/theme = BlulocoLight/theme = catppuccin-mocha/' "$GHOSTTY_OVERRIDES"
                              sed -i "" 's/theme = catppuccin-latte/theme = catppuccin-mocha/' "$GHOSTTY_OVERRIDES"
                          fi
                          log "   ✅ Updated Ghostty theme to catppuccin-mocha (dark mode)"
                      elif ! grep -q 'theme = catppuccin-mocha\|theme = dracula' "$GHOSTTY_OVERRIDES"; then
                          # Add dark theme if no theme is set
                          if [[ "$DRY_RUN" != "true" ]]; then
                              echo "theme = catppuccin-mocha" >> "$GHOSTTY_OVERRIDES"
                          fi
                          log "   ✅ Added Ghostty theme catppuccin-mocha (dark mode)"
                      else
                          log "   ✅ Ghostty already using a dark theme"
                      fi
                  fi
                  
                  # Smart Ghostty reload logic - use config reload instead of restart
                  if [[ "$DRY_RUN" != "true" ]]; then
                      # Try to reload Ghostty configuration using AppleScript
                      if osascript -e 'tell application "System Events" to tell process "Ghostty" to perform action "AXPress" of (first button whose description is "reload")' 2>/dev/null; then
                          log "   🔄 Reloaded Ghostty configuration via AppleScript"
                      elif osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1' 2>/dev/null; then
                          log "   🔄 Reloaded Ghostty configuration via menu action"
                      else
                          # Fallback: Check if Ghostty is running and try alternative methods
                          if pgrep -f Ghostty >/dev/null 2>&1; then
                              # Alternative: Try to send a signal or use other IPC if available
                              log "   💡 Ghostty is running - theme changes will apply to new windows automatically"
                              log "   ℹ️  For immediate effect in existing windows, use the reload_config keybind or menu"
                          else
                              log "   ℹ️  Ghostty not currently running - theme will apply when launched"
                          fi
                      fi
                  else
                      log "   🔄 Would reload Ghostty configuration (no restart needed)"
                  fi
              else
                  log "   ❌ Ghostty overrides file not found: $GHOSTTY_OVERRIDES"
              fi
              
              # Update shell themes
              log "🐚 Updating shell theme configurations..."
              
              # Set environment variables for current session
              export BAT_THEME="$BAT_THEME"
              
              # Set shell theme environment variables
              if [[ "$APPEARANCE" == "light" ]]; then
                  export NUSHELL_THEME="light"
                  export FISH_THEME="light"
                  export ZSH_THEME="light"
              else
                  export NUSHELL_THEME="dark"
                  export FISH_THEME="dark"
                  export ZSH_THEME="dark"
              fi
              
              # Write shell theme to persistent files for new shell sessions
              if [[ "$DRY_RUN" != "true" ]]; then
                  echo "$NUSHELL_THEME" > "$HOME/.cache/nushell_theme" 2>/dev/null || true
                  echo "$FISH_THEME" > "$HOME/.cache/fish_theme" 2>/dev/null || true
                  echo "$ZSH_THEME" > "$HOME/.cache/zsh_theme" 2>/dev/null || true
              fi
              log "   ✅ Updated shell theme caches ($APPEARANCE mode)"
              log "   ✅ Set BAT_THEME to $BAT_THEME"
              
              log ""
              if [[ "$DRY_RUN" == "true" ]]; then
                  log "🔍 DRY RUN COMPLETE - No actual changes were made"
                  log "Run without --dry-run to apply these changes"
              else
                  log "🎉 Theme switching complete! ($CATPPUCCIN_FLAVOR mode active)"
                  log "💡 Restart terminal applications to see all changes"
              fi
            '';
          };
          
          # LaunchAgent for automatic theme switching  
          "Library/LaunchAgents/com.user.catppuccin-theme-switcher.plist" = {
            text = ''
              <?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
              <plist version="1.0">
              <dict>
                  <key>Label</key>
                  <string>com.user.catppuccin-theme-switcher</string>
                  <key>ProgramArguments</key>
                  <array>
                      <string>/Users/${user}/.local/bin/catppuccin-theme-switcher</string>
                      <string>--quiet</string>
                  </array>
                  <key>WatchPaths</key>
                  <array>
                      <string>/Users/${user}/Library/Preferences/.GlobalPreferences.plist</string>
                  </array>
                  <key>RunAtLoad</key>
                  <true/>
              </dict>
              </plist>
            '';
          };
        };

        # Ensure user shells and GUI apps see Enchant/Aspell settings + work configuration
        sessionVariables = {
          ENCHANT_ORDERING = "en:aspell,es:aspell,*:aspell";
          ASPELL_CONF = "dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell";
          STARSHIP_CONFIG = "${config.home.homeDirectory}/.config/starship.toml";
          # Set Xcode developer directory to beta version for GUI applications
          DEVELOPER_DIR = "/Applications/Xcode-beta.app/Contents/Developer";
          # Work configuration environment variables
          WORK_COMPANY_NAME = workConfig.companyName or "CompanyName";
          WORK_GIT_DIR_PATTERN = workConfig.gitWorkDirPattern or "~/work/**";
          WORK_DB_NAME = workConfig.databaseName or "your_db";
          WORK_DB_HOST = workConfig.databaseHost or "localhost";
          WORK_DB_PORT = workConfig.databasePort or "3306";
          WORK_OP_VAULT = workConfig.opVaultName or "Work";
          WORK_OP_ITEM = workConfig.opItemName or "CompanyName";
        };

        stateVersion = "25.05";
      };

      # Test: re-enable font management to see if it still causes issues
      fonts.fontconfig.enable = true;

      # Enable catppuccin with automatic light/dark switching
      catppuccin = {
        enable = true;
        flavor = "latte"; # Default light theme
        accent = "mauve"; # Accent color
        # Enable automatic theme switching for supported programs
        # Programs will automatically use "latte" in light mode and "mocha" in dark mode
        # Disable starship integration to prevent conflicts with our manual config
        starship.enable = false;
      };

      # Enable the local nushell module
      local.nushell.enable = true;
      
      # Clean up backup files to prevent collisions
      home.activation.cleanupBackupFiles = lib.hm.dag.entryBefore ["checkFilesChanged"] ''
        # Remove any existing .bak files that would conflict with home-manager backup creation
        echo "🧹 Cleaning up old backup files to prevent home-manager collisions..."
        $DRY_RUN_CMD rm -f ~/.config/starship.toml.bak
        $DRY_RUN_CMD rm -f ~/.config/zellij/config.kdl.bak
        $DRY_RUN_CMD rm -f ~/.config/atuin/config.toml.bak
        # Also clean up any other .bak files in common config directories
        $DRY_RUN_CMD find ~/.config -name "*.bak" -type f -delete 2>/dev/null || true
        echo "✅ Backup file cleanup completed"
      '';
      
      # Set up automatic theme switching
      home.activation.setupCatppuccinThemeSwitcher = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Load the LaunchAgent for automatic theme switching
        $DRY_RUN_CMD launchctl unload ~/Library/LaunchAgents/com.user.catppuccin-theme-switcher.plist 2>/dev/null || true
        $DRY_RUN_CMD launchctl load -w ~/Library/LaunchAgents/com.user.catppuccin-theme-switcher.plist 2>/dev/null || true
        
        # Run the theme switcher once to set initial theme
        $DRY_RUN_CMD ~/.local/bin/catppuccin-theme-switcher || true
        
        echo "Catppuccin automatic theme switcher has been set up!"
      '';

      programs = {
        _1password-shell-plugins = {
          # enable 1Password shell plugins for bash, zsh
          enable = true;
          # the specified packages as well as 1Password CLI will be
          # automatically installed and configured to use shell plugins
          plugins = with pkgs; [ cachix gh glab ];
        };

        atuin = {
          enable = true;
          daemon.enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          settings = {
            # General settings
            auto_sync = true;
            sync_frequency = "5m";
            sync_address = "https://api.atuin.sh";
            
            # Search settings
            search_mode = "prefix";
            filter_mode = "global";
            style = "compact";
            
            # History settings
            inline_height = 40;
            show_preview = true;
            max_preview_height = 4;
          };
        };

        helix.enable = true;

        jujutsu = {
          enable = true;
          settings = {
            ui.editor = "nvim";
            user = {
              email = userConfig.email;
              name = userConfig.name;
            };
          };
        };

        mise = {
          enable = true;
          # Disable shell integrations to prevent PATH conflicts - we manage PATH manually
          enableNushellIntegration = false;
          enableZshIntegration = false;
          enableFishIntegration = false;
          # Use nixpkgs mise package instead of flake to avoid SDK issues
          # package = inputs.mise.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };

        starship = {
          enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
          enableFishIntegration = true;
          settings = fromTOML(builtins.readFile ./starship.toml);
        };

        vscode = {
          enable = true;
          mutableExtensionsDir = true;
        };

        yazi = {
          enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          settings = {
            mgr = {
              ratio = [1 3 4];
            };
          };
        };

        zoxide = {
          enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
        };

        fish = {
          enable = true;
          shellInit = ''
            # Nix daemon initialization (equivalent to Nushell initialization)
            if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
                set -gx NIX_SSL_CERT_FILE '/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt'
                set -gx NIX_PROFILES '/nix/var/nix/profiles/default ~/.nix-profile'
                set -gx NIX_PATH 'nixpkgs=flake:nixpkgs'
                fish_add_path --prepend '/nix/var/nix/profiles/default/bin'
            end

            # Environment variables (matching nushell env.nu)
            set -gx AWS_REGION "us-east-1"
            set -gx AWS_DEFAULT_REGION "us-east-1"
            set -gx DOTNET_ROOT "/usr/local/share/dotnet"
            set -gx EMACSDIR "~/.emacs.d"
            set -gx DOOMDIR "~/.doom.d"
            set -gx DOOMLOCALDIR "~/.emacs.d/.local"
            set -gx CARGO_HOME "$HOME/.cargo"
            
            # Set Xcode developer directory to beta version
            set -gx DEVELOPER_DIR "/Applications/Xcode-beta.app/Contents/Developer"

            # Enchant/Aspell configuration (matching nushell)
            set -gx ENCHANT_ORDERING 'en:aspell,es:aspell,*:aspell'
            set -gx ASPELL_CONF 'dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell'

            # Use centralized PATH configuration from modules/path-config.nix
            ${pathConfig.fish.pathSetup or "# PATH config not available"}

            # Editor configuration
            set -gx EDITOR "nvim"
            
            # Load theme from cache file set by catppuccin theme switcher
            if test -f ~/.cache/fish_theme
                set -gx FISH_THEME (cat ~/.cache/fish_theme 2>/dev/null | string trim)
            else
                set -gx FISH_THEME "dark"
            end
            
            # Set LS_COLORS and BAT_THEME based on fish theme
            if test "$FISH_THEME" = "light"
                # Light theme LS_COLORS (higher contrast for light backgrounds)
                set -gx LS_COLORS "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36"
                set -gx BAT_THEME "GitHub"
            else
                # Dark theme LS_COLORS (higher contrast for dark backgrounds)
                set -gx LS_COLORS "rs=0:di=01;94:ln=01;96:mh=00:pi=40;93:so=01;95:do=01;95:bd=40;93;01:cd=40;93;01:or=40;91;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=94;42:st=37;44:ex=01;92:*.tar=01;91:*.tgz=01;91:*.arc=01;91:*.arj=01;91:*.taz=01;91:*.lha=01;91:*.lz4=01;91:*.lzh=01;91:*.lzma=01;91:*.tlz=01;91:*.txz=01;91:*.tzo=01;91:*.t7z=01;91:*.zip=01;91:*.z=01;91:*.Z=01;91:*.dz=01;91:*.gz=01;91:*.lrz=01;91:*.lz=01;91:*.lzo=01;91:*.xz=01;91:*.bz2=01;91:*.bz=01;91:*.tbz=01;91:*.tbz2=01;91:*.tz=01;91:*.deb=01;91:*.rpm=01;91:*.jar=01;91:*.war=01;91:*.ear=01;91:*.sar=01;91:*.rar=01;91:*.alz=01;91:*.ace=01;91:*.zoo=01;91:*.cpio=01;91:*.7z=01;91:*.rz=01;91:*.cab=01;91:*.jpg=01;95:*.jpeg=01;95:*.gif=01;95:*.bmp=01;95:*.pbm=01;95:*.pgm=01;95:*.ppm=01;95:*.tga=01;95:*.xbm=01;95:*.xpm=01;95:*.tif=01;95:*.tiff=01;95:*.png=01;95:*.svg=01;95:*.svgz=01;95:*.mng=01;95:*.pcx=01;95:*.mov=01;95:*.mpg=01;95:*.mpeg=01;95:*.m2v=01;95:*.mkv=01;95:*.webm=01;95:*.ogm=01;95:*.mp4=01;95:*.m4v=01;95:*.mp4v=01;95:*.vob=01;95:*.qt=01;95:*.nuv=01;95:*.wmv=01;95:*.asf=01;95:*.rm=01;95:*.rmvb=01;95:*.flc=01;95:*.avi=01;95:*.fli=01;95:*.flv=01;95:*.gl=01;95:*.dl=01;95:*.xcf=01;95:*.xwd=01;95:*.yuv=01;95:*.cgm=01;95:*.emf=01;95:*.ogv=01;95:*.ogx=01;95:*.aac=00;96:*.au=00;96:*.flac=00;96:*.m4a=00;96:*.mid=00;96:*.midi=00;96:*.mka=00;96:*.mp3=00;96:*.mpc=00;96:*.ogg=00;96:*.ra=00;96:*.wav=00;96:*.oga=00;96:*.opus=00;96:*.spx=00;96:*.xspf=00;96"
                set -gx BAT_THEME "ansi"
            end
          '';

          # Interactive configuration
          interactiveShellInit = ''
            # Vi mode (matching nushell's vi edit mode)
            fish_vi_key_bindings

            # Let Starship handle the prompt - no custom fish_prompt function
            # This allows starship.toml configuration to work properly
            
            # Set Fish syntax highlighting colors based on theme
            if test "$FISH_THEME" = "light"
                # Light theme Fish colors (higher contrast for light backgrounds)
                set -g fish_color_normal "333333"                  # normal text - dark gray
                set -g fish_color_command "0066cc"                # commands - blue
                set -g fish_color_keyword "990099"                # keywords - purple
                set -g fish_color_quote "009900"                  # quoted text - green
                set -g fish_color_redirection "cc6600"            # redirections - orange
                set -g fish_color_end "cc0000"                    # command separators - red
                set -g fish_color_error "cc0000" --bold          # errors - bold red
                set -g fish_color_param "666666"                 # parameters - medium gray
                set -g fish_color_comment "999999"               # comments - light gray
                set -g fish_color_match --background="ffff00"     # matching brackets - yellow background
                set -g fish_color_selection --background="e6e6e6" # selected text - light gray background
                set -g fish_color_search_match --background="ffff99" # search matches - light yellow background
                set -g fish_color_history_current --bold         # current history item
                set -g fish_color_operator "cc6600"              # operators - orange
                set -g fish_color_escape "009999"                # escape sequences - cyan
                set -g fish_color_cwd "0066cc"                   # current directory - blue
                set -g fish_color_cwd_root "cc0000"              # root directory - red
                set -g fish_color_valid_path --underline        # valid paths - underlined
                set -g fish_color_autosuggestion "cccccc"        # autosuggestions - very light gray
                set -g fish_color_user "009900"                  # username - green
                set -g fish_color_host "0066cc"                  # hostname - blue
            else
                # Dark theme Fish colors (higher contrast for dark backgrounds)
                set -g fish_color_normal "ffffff"                # normal text - white
                set -g fish_color_command "66b3ff"              # commands - light blue
                set -g fish_color_keyword "ff66ff"              # keywords - magenta
                set -g fish_color_quote "66ff66"                # quoted text - light green
                set -g fish_color_redirection "ffaa66"          # redirections - light orange
                set -g fish_color_end "ff6666"                  # command separators - light red
                set -g fish_color_error "ff6666" --bold        # errors - bold light red
                set -g fish_color_param "cccccc"               # parameters - light gray
                set -g fish_color_comment "888888"             # comments - medium gray
                set -g fish_color_match --background="666600"   # matching brackets - dark yellow background
                set -g fish_color_selection --background="444444" # selected text - dark gray background
                set -g fish_color_search_match --background="666633" # search matches - dark yellow background
                set -g fish_color_history_current --bold       # current history item
                set -g fish_color_operator "ffaa66"            # operators - light orange
                set -g fish_color_escape "66ffff"              # escape sequences - light cyan
                set -g fish_color_cwd "66b3ff"                 # current directory - light blue
                set -g fish_color_cwd_root "ff6666"            # root directory - light red
                set -g fish_color_valid_path --underline      # valid paths - underlined
                set -g fish_color_autosuggestion "666666"      # autosuggestions - medium gray
                set -g fish_color_user "66ff66"                # username - light green
                set -g fish_color_host "66b3ff"                # hostname - light blue
            end
            
            # Authoritative PATH override - ensures our configuration takes precedence over all tools
            ${pathConfig.fish.pathOverride or "# PATH override not available"}
          '';

          # Function definitions (matching some nushell functions)
          functions = {
            # Equivalent to nushell's gp function
            gp = ''
              git fetch --all -p
              git pull
              git submodule update --recursive
            '';
            
            # Equivalent to nushell's search alias  
            search = ''
              rg -p --glob '!node_modules/*' $argv
            '';
            
            # Equivalent to nushell's diff alias
            diff = ''
              difft $argv
            '';

            # Nix shortcuts (matching nushell)
            nb = ''
              pushd ~/darwin-config
              nix run .#build
              popd
            '';
            
            ns = ''
              pushd ~/darwin-config
              nix run .#build-switch  
              popd
            '';

            # Terminal and editor shortcuts (matching nushell aliases)
            tg = ''
              $EDITOR ~/.config/ghostty/config
            '';
            
            tgg = ''
              $EDITOR ~/.config/ghostty/overrides.conf
            '';
            
            nnc = ''
              $EDITOR ~/darwin-config/modules/nushell/config.nu
            '';
            
            nne = ''
              $EDITOR ~/darwin-config/modules/nushell/env.nu
            '';

            # Fish config editing (in home-manager.nix)
            ffc = ''
              $EDITOR ~/darwin-config/modules/home-manager.nix
            '';
            
            # Manual catppuccin theme switching
            catppuccin-theme-switch = ''
              ~/.local/bin/catppuccin-theme-switcher
            '';
            
            # Official yazi shell wrapper for directory changing
            y = ''
              set tmp (mktemp -t "yazi-cwd.XXXXXX")
              yazi $argv --cwd-file="$tmp"
              if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
                  builtin cd -- "$cwd"
              end
              rm -f -- "$tmp"
            '';
          };

          # Abbreviations (like aliases but expandable)
          shellAbbrs = {
            # Doom Emacs shortcuts (matching nushell)
            ds = "doom sync --aot --gc -j (nproc)";
            dup = "doom sync -u --aot --gc -j (nproc)";
            sdup = "doom sync -u --aot --gc -j (nproc) --rebuild";
            
            # Emacs shortcuts
            edd = "emacs --daemon=doom";
            pke = "pkill -9 Emacs";
            tt = "emacs -nw";
            
            # Quick navigation
            ll = "ls -la";
            la = "ls -A";
            l = "ls -CF";
            
            # Git shortcuts
            g = "git";
            ga = "git add";
            gc = "git commit";
            gco = "git checkout";
            gs = "git status";
            gd = "git diff";
            gl = "git log";
          };
        };

        # zellij is installed via homebrew and configured manually
        # We use external config file instead of home-manager settings
        
        # Git configuration
        git = {
          enable = true;
          ignores = (import ./git-ignores.nix { inherit config pkgs lib; }).git.ignores;
          userName = userConfig.name;
          lfs.enable = true;
          extraConfig = {
            init.defaultBranch = "main";
            core = {
              editor = "nvim";
              autocrlf = false;
              eol = "lf";
              ignorecase = false;
            };
            commit.gpgsign = false;
            diff.colorMoved = "zebra";
            fetch.prune = true;
            pull.rebase = true;
            push.autoSetupRemote = true;
            rebase.autoStash = true;
            safe.directory = [
              "*"
              "/Users/${user}/darwin-config"
              "/nix/store/*"
              "/opt/homebrew/*"
            ];
            includeIf."gitdir:/Users/${user}/${workDirName}/**".path = "/Users/${user}/.config/git/config-work";
            include.path = "/Users/${user}/.config/git/config-personal";
          };
        };

        # SSH configuration
        ssh = {
          enable = true;
          includes = [ "/Users/${user}/.ssh/config_external" ];
          matchBlocks."github.com" = {
            identitiesOnly = true;
            identityFile = [ "/Users/${user}/.ssh/id_ed25519" ];
          };
        };
      } // (import ./shell-config.nix { inherit config pkgs lib; }).programs;

      # Shell modules are now conditionally imported based on defaultShell

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        { path = "/Applications/Emacs.app/"; }
        { path = "/Applications/Zed Preview.app/"; }
        { path = "/Applications/Ghostty.app/"; }
        { path = "/Applications/WarpPreview.app/"; }
        { path = "/Applications/Safari.app/"; }
        { path = "/Applications/Zen.app/"; }
        { path = "/Applications/Google Chrome.app/"; }
        { path = "/Applications/Microsoft Edge.app/"; }
        { path = "/Applications/Microsoft Teams.app/"; }
        { path = "/Applications/Microsoft Outlook.app/"; }
        { path = "/Applications/Discord.app/"; }
        { path = "/System/Applications/Music.app/"; }
        { path = "/System/Applications/Calendar.app/"; }
        { path = "/System/Applications/System Settings.app/"; }
      ];
    };
  };
}
