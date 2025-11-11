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
      $DRY_RUN_CMD rm -f ~/.config/atuin/config.toml.bak
      # Also clean up any other .bak files in common config directories
      $DRY_RUN_CMD find ~/.config -name "*.bak" -type f -delete 2>/dev/null || true
      echo "✅ Backup file cleanup completed"
    '';

    # Clean up stale atuin socket to ensure daemon can start
    cleanupAtuinSocket = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      echo "🧹 Cleaning up atuin daemon socket..."
      # Remove stale socket file if it exists (prevents "Address already in use" errors)
      $DRY_RUN_CMD rm -f ~/.local/share/atuin/daemon.sock
      echo "✅ Atuin socket cleanup completed"
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

    autoPinEmacsAfterBuild = lib.hm.dag.entryAfter ["linkGeneration"] ''
      PIN_FILE="$HOME/.cache/emacs-git-pin"
      HASH_FILE="$HOME/.cache/emacs-git-pin-hash"
      STORE_FILE="$HOME/.cache/emacs-git-store-path"

      # Only auto-refresh pin if already pinned
      # Initial pinning must be done manually by running 'emacs-pin' after build
      if [[ -f "$PIN_FILE" ]]; then
        STORED_PATH=""
        if [[ -f "$STORE_FILE" ]]; then
          STORED_PATH="$(cat "$STORE_FILE" 2>/dev/null || true)"
        fi

        # If no stored path or path no longer exists, auto-pin to current build
        if [[ -z "$STORED_PATH" || ! -e "$STORED_PATH" ]]; then
          echo "📌 Emacs pinned but stored build path missing; auto-pinning to current overlay build..."
          if command -v emacs-pin-rs >/dev/null 2>&1; then
            $DRY_RUN_CMD emacs-pin-rs || true
          elif command -v emacs-pin >/dev/null 2>&1; then
            $DRY_RUN_CMD emacs-pin || true
          fi
        # Detect legacy builds that predate the Liquid Glass Assets.car integration
        elif [[ ! -e "$STORED_PATH/Applications/Emacs.app/Contents/Resources/Assets.car" ]]; then
          echo "📌 Emacs pinned build missing Liquid Glass Assets.car; refreshing stored path..."
          if command -v emacs-pin-rs >/dev/null 2>&1; then
            $DRY_RUN_CMD emacs-pin-rs || true
          elif command -v emacs-pin >/dev/null 2>&1; then
            $DRY_RUN_CMD emacs-pin || true
          fi
        fi
      fi
    '';
  };
}
