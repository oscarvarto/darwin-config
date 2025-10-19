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

    # Auto-pin Emacs after a successful build if pinned store path was GC'd
    autoPinEmacsAfterBuild = lib.hm.dag.entryAfter ["writeBoundary"] ''
      PIN_FILE="$HOME/.cache/emacs-git-pin"
      HASH_FILE="$HOME/.cache/emacs-git-pin-hash"
      STORE_FILE="$HOME/.cache/emacs-git-store-path"

      # Only if currently pinned
      if [[ -f "$PIN_FILE" ]]; then
        STORED_PATH=""
        if [[ -f "$STORE_FILE" ]]; then
          STORED_PATH="$(cat "$STORE_FILE" 2>/dev/null || true)"
        fi

        # If no stored path or path no longer exists, auto-pin to current build
        if [[ -z "$STORED_PATH" || ! -e "$STORED_PATH" ]]; then
          echo "📌 Emacs pinned but stored build path missing; auto-pinning to current overlay build..."
          # Run emacs-pin without args to capture current overlay commit and built outPath
          if command -v emacs-pin-rs >/dev/null 2>&1; then
            $DRY_RUN_CMD emacs-pin-rs || true
          elif command -v emacs-pin >/dev/null 2>&1; then
            $DRY_RUN_CMD emacs-pin || true
          else
            echo "⚠️  emacs-pin command not found; skipping auto-pin"
          fi
        fi
      fi
    '';
  };
}
