{ config, pkgs, lib, user, ... }:

{
  home.activation = {
    # Clean up backup files to prevent collisions
    cleanupBackupFiles = lib.hm.dag.entryBefore ["checkFilesChanged"] ''
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
    setupCatppuccinThemeSwitcher = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Load the LaunchAgent for automatic theme switching
      $DRY_RUN_CMD launchctl unload ~/Library/LaunchAgents/com.user.catppuccin-theme-switcher.plist 2>/dev/null || true
      $DRY_RUN_CMD launchctl load -w ~/Library/LaunchAgents/com.user.catppuccin-theme-switcher.plist 2>/dev/null || true
      
      # Run the theme switcher once to set initial theme
      $DRY_RUN_CMD ~/.local/bin/catppuccin-theme-switcher || true
      
      echo "Catppuccin automatic theme switcher has been set up!"
    '';
  };
}