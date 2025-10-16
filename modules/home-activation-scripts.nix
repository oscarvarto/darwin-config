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
