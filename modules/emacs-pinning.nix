{ pkgs, user, inputs, ... }:
let
  # Emacs pinning system with hash management
  pinFile = "/Users/${user}/.cache/emacs-git-pin";
  hashFile = "/Users/${user}/.cache/emacs-git-pin-hash";

  isPinned = builtins.pathExists pinFile;

  pinnedCommit = if isPinned
    then builtins.replaceStrings ["\n"] [""] (builtins.readFile pinFile)
    else null;

  pinnedHash = if isPinned && builtins.pathExists hashFile
    then builtins.replaceStrings ["\n"] [""] (builtins.readFile hashFile)
    else null;

  # Create emacs package - pinned or latest
  emacsPackage = if isPinned && pinnedCommit != null && pinnedHash != null
    then
      # Use pinned version with stored hash
      (inputs.emacs-overlay.packages.${pkgs.stdenv.hostPlatform.system}.emacs-git.overrideAttrs (oldAttrs: {
        version = "31.0.50-${builtins.substring 0 7 pinnedCommit}";
        src = pkgs.fetchFromGitHub {
          owner = "emacs-mirror";
          repo = "emacs";
          rev = pinnedCommit;
          sha256 = pinnedHash;
        };
      }))
    else
      # Use latest version from overlay (when not pinned or hash missing)
      inputs.emacs-overlay.packages.${pkgs.stdenv.hostPlatform.system}.emacs-git;

  # Apply emacs configuration overrides
  configuredEmacs = emacsPackage.override {
    withNativeCompilation = true;
    withImageMagick = true;
    withWebP = true;
    withTreeSitter = true;
    withSQLite3 = true;
    withXwidgets = true;
    withMailutils = true;
  };

  emacsPin = pkgs.writeScriptBin "emacs-pin" ''
    #!/usr/bin/env bash
    # Pin emacs-git to current nix-provided commit (no args) or specified commit

    set -euo pipefail

    COMMIT="''${1:-}"
    CACHE_DIR="''${HOME}/.cache"
    PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
    HASH_FILE="''${CACHE_DIR}/emacs-git-pin-hash"

    # Create cache directory if it doesn't exist
    mkdir -p "''${CACHE_DIR}"

    # Function to extract current emacs-git commit from nix configuration
    extract_current_emacs_commit() {
      local CONFIG_PATH="$(dirname "$(readlink -f "''${BASH_SOURCE[0]}")")"

      # Try to find the darwin-config directory
      if [[ -d "''${HOME}/darwin-config" ]]; then
        CONFIG_PATH="''${HOME}/darwin-config"
      elif [[ -d "/Users/''${USER}/darwin-config" ]]; then
        CONFIG_PATH="/Users/''${USER}/darwin-config"
      fi

      echo $'\U1F50D Extracting commit hash from current nix-provided emacs-git...' >&2

      # Extract commit hash from the current configuration
      local CURRENT_COMMIT
      CURRENT_COMMIT=$(cd "''${CONFIG_PATH}" && nix eval ".#darwinConfigurations.predator.config.home-manager.users.''${USER}.home.packages" \
        --apply 'pkgs: let emacsPackage = builtins.filter (p: builtins.match ".*emacs-git.*" p.name != null) pkgs; in if builtins.length emacsPackage > 0 then (builtins.head emacsPackage).src.rev or null else null' \
        --raw)

      if [[ -n "''${CURRENT_COMMIT}" && "''${CURRENT_COMMIT}" != "null" ]]; then
        echo "''${CURRENT_COMMIT}"
      else
        return 1
      fi
    }

    # Function to extract current emacs-git hash from nix configuration
    extract_current_emacs_hash() {
      local CONFIG_PATH="$(dirname "$(readlink -f "''${BASH_SOURCE[0]}")")"

      # Try to find the darwin-config directory
      if [[ -d "''${HOME}/darwin-config" ]]; then
        CONFIG_PATH="''${HOME}/darwin-config"
      elif [[ -d "/Users/''${USER}/darwin-config" ]]; then
        CONFIG_PATH="/Users/''${USER}/darwin-config"
      fi

      echo $'\U1F511 Extracting hash from current nix-provided emacs-git...' >&2

      # Extract hash from the current configuration
      local CURRENT_HASH
      CURRENT_HASH=$(cd "''${CONFIG_PATH}" && nix eval ".#darwinConfigurations.predator.config.home-manager.users.''${USER}.home.packages" \
        --apply 'pkgs: let emacsPackage = builtins.filter (p: builtins.match ".*emacs-git.*" p.name != null) pkgs; in if builtins.length emacsPackage > 0 then (builtins.head emacsPackage).src.outputHash or null else null' \
        --raw)

      if [[ -n "''${CURRENT_HASH}" && "''${CURRENT_HASH}" != "null" ]]; then
        echo "''${CURRENT_HASH}"
      else
        return 1
      fi
    }

    # If no commit hash provided, extract from current emacs
    if [[ -z "''${COMMIT}" ]]; then
      echo $'\U1F4A1 No commit hash provided. Extracting from current nix-provided emacs-git...'

      if COMMIT=$(extract_current_emacs_commit); then
        echo $'\U2705 Found current commit: '"''${COMMIT}"

        # Try to extract the corresponding hash as well
        if HASH=$(extract_current_emacs_hash); then
          echo $'\U2705 Found current hash: '"''${HASH}"

          # Save both directly without fetching
          echo "''${COMMIT}" > "''${PIN_FILE}"
          echo "''${HASH}" > "''${HASH_FILE}"

          echo $'\U1F4CC Pinned emacs-git to current commit: '"''${COMMIT}"
          echo $'\U1F511 Stored hash: '"''${HASH}"
          echo $'\U1F4A1 Rebuild your configuration: nb && ns'
          exit 0
        else
          echo $'\U26A0\UFE0F Could not extract current hash, will fetch it...'
        fi
      else
        echo $'\U274C Could not extract current emacs-git commit from configuration'
        echo "   Please specify a commit hash manually: emacs-pin <commit-hash>"
        echo "   You can find commits at: https://github.com/emacs-mirror/emacs/commits/master"
        echo "   Example: emacs-pin abc123def456"
        exit 1
      fi
    fi

    # Validate commit hash format (basic check)
    if [[ ! "''${COMMIT}" =~ ^[a-f0-9]{7,40}$ ]]; then
      echo $'\U274C Invalid commit hash format: '"''${COMMIT}"
      exit 1
    fi

    echo $'\U1F50D Fetching hash for commit '"''${COMMIT}"$'...'

    # Use system-installed nix-prefetch-github
    HASH_RESULT=$(nix-prefetch-github emacs-mirror emacs --rev "''${COMMIT}" 2>/dev/null)
    HASH=$(echo "''${HASH_RESULT}" | grep '"hash"' | sed 's/.*"hash": "\([^"]*\)".*/\1/')

    if [[ -z "''${HASH}" || "''${HASH}" == "null" ]]; then
      echo $'\U274C Failed to fetch hash for commit '"''${COMMIT}"
      echo "   Please check that the commit exists in the emacs-mirror/emacs repository."
      exit 1
    fi

    # Save the commit hash and its corresponding SHA256
    echo "''${COMMIT}" > "''${PIN_FILE}"
    echo "''${HASH}" > "''${HASH_FILE}"

    echo $'\U1F4CC Pinned emacs-git to commit: '"''${COMMIT}"
    echo $'\U1F511 Stored hash: '"''${HASH}"
    echo $'\U1F4A1 Rebuild your configuration: nb && ns'
  '';

  emacsUnpin = pkgs.writeScriptBin "emacs-unpin" ''
    #!/usr/bin/env bash
    # Unpin emacs-git to use latest commit

    set -euo pipefail

    CACHE_DIR="''${HOME}/.cache"
    PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
    HASH_FILE="''${CACHE_DIR}/emacs-git-pin-hash"

    if [[ -f "''${PIN_FILE}" ]]; then
      PINNED_COMMIT=$(cat "''${PIN_FILE}")
      rm "''${PIN_FILE}"
      [[ -f "''${HASH_FILE}" ]] && rm "''${HASH_FILE}"
      echo $'\U1F513 Unpinned emacs-git from commit: '"''${PINNED_COMMIT}"
      echo $'\U1F4A1 Rebuild your configuration: nb && ns'
      echo "   This will use the latest emacs-git commit from the overlay."
    else
      echo $'\U2139\UFE0F emacs-git is not currently pinned'
    fi
  '';

  emacsPinDiff = pkgs.writeScriptBin "emacs-pin-diff" ''
    #!/usr/bin/env bash
    # Show differences between pinned and current emacs-git commits

    set -euo pipefail

    CACHE_DIR="''${HOME}/.cache"
    PIN_FILE="''${CACHE_DIR}/emacs-git-pin"

    # Function to extract current emacs-git commit from nix configuration
    extract_current_emacs_commit() {
      local CONFIG_PATH="$(dirname "$(readlink -f "''${BASH_SOURCE[0]}")")"

      # Try to find the darwin-config directory
      if [[ -d "''${HOME}/darwin-config" ]]; then
        CONFIG_PATH="''${HOME}/darwin-config"
      elif [[ -d "/Users/''${USER}/darwin-config" ]]; then
        CONFIG_PATH="/Users/''${USER}/darwin-config"
      fi

      # Extract commit hash from the current configuration
      local CURRENT_COMMIT
      CURRENT_COMMIT=$(cd "''${CONFIG_PATH}" && nix eval ".#darwinConfigurations.predator.config.home-manager.users.''${USER}.home.packages" \
        --apply 'pkgs: let emacsPackage = builtins.filter (p: builtins.match ".*emacs-git.*" p.name != null) pkgs; in if builtins.length emacsPackage > 0 then (builtins.head emacsPackage).src.rev or null else null' \
        --raw)

      if [[ -n "''${CURRENT_COMMIT}" && "''${CURRENT_COMMIT}" != "null" ]]; then
        echo "''${CURRENT_COMMIT}"
      else
        return 1
      fi
    }

    # Get current overlay commit
    CURRENT_COMMIT=""
    if ! CURRENT_COMMIT=$(extract_current_emacs_commit 2>/dev/null); then
      echo $'\U274C Could not extract current emacs-git commit from configuration'
      exit 1
    fi

    if [[ -f "''${PIN_FILE}" ]]; then
      PINNED_COMMIT=$(cat "''${PIN_FILE}")

      if [[ "''${PINNED_COMMIT}" == "''${CURRENT_COMMIT}" ]]; then
        echo $'\U2705 Pinned commit matches current overlay commit'
        echo "   Commit: ''${PINNED_COMMIT}"
      else
        echo $'\U1F4CC Pinned commit: '"''${PINNED_COMMIT}"
        echo $'\U1F4C8 Current commit: '"''${CURRENT_COMMIT}"
        echo ""
        echo $'\U1F517 Compare commits:'
        echo "   https://github.com/emacs-mirror/emacs/compare/''${PINNED_COMMIT}...''${CURRENT_COMMIT}"
        echo ""
        echo $'\U1F4A1 To update to current: emacs-pin (without arguments)'
        echo $'\U1F4A1 To unpin: emacs-unpin'
      fi
    else
      echo $'\U1F513 emacs-git is not pinned'
      echo $'\U1F4C8 Current overlay commit: '"''${CURRENT_COMMIT}"
      echo ""
      echo $'\U1F4A1 To pin to current: emacs-pin (without arguments)'
    fi
  '';

  emacsPinStatus = pkgs.writeScriptBin "emacs-pin-status" ''
    #!/usr/bin/env bash
    # Show current emacs-git pinning status

    set -euo pipefail

    CACHE_DIR="''${HOME}/.cache"
    PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
    HASH_FILE="''${CACHE_DIR}/emacs-git-pin-hash"

    # Function to extract current emacs-git commit from nix configuration
    extract_current_emacs_commit() {
      local CONFIG_PATH="$(dirname "$(readlink -f "''${BASH_SOURCE[0]}")")"

      # Try to find the darwin-config directory
      if [[ -d "''${HOME}/darwin-config" ]]; then
        CONFIG_PATH="''${HOME}/darwin-config"
      elif [[ -d "/Users/''${USER}/darwin-config" ]]; then
        CONFIG_PATH="/Users/''${USER}/darwin-config"
      fi

      # Extract commit hash from the current configuration
      local CURRENT_COMMIT
      CURRENT_COMMIT=$(cd "''${CONFIG_PATH}" && nix eval ".#darwinConfigurations.predator.config.home-manager.users.''${USER}.home.packages" \
        --apply 'pkgs: let emacsPackage = builtins.filter (p: builtins.match ".*emacs-git.*" p.name != null) pkgs; in if builtins.length emacsPackage > 0 then (builtins.head emacsPackage).src.rev or null else null' \
        --raw)

      if [[ -n "''${CURRENT_COMMIT}" && "''${CURRENT_COMMIT}" != "null" ]]; then
        echo "''${CURRENT_COMMIT}"
      else
        return 1
      fi
    }

    # Get current overlay commit for comparison
    CURRENT_OVERLAY_COMMIT=""
    if CURRENT_OVERLAY_COMMIT=$(extract_current_emacs_commit 2>/dev/null); then
      echo $'\U1F4C8 Current nix-provided emacs-git commit: '"''${CURRENT_OVERLAY_COMMIT}"
      echo $'\U1F517 View current: https://github.com/emacs-mirror/emacs/commit/'"''${CURRENT_OVERLAY_COMMIT}"
      echo ""
    fi

    if [[ -f "''${PIN_FILE}" ]]; then
      PINNED_COMMIT=$(cat "''${PIN_FILE}")
      echo $'\U1F4CC emacs-git is pinned to commit: '"''${PINNED_COMMIT}"
      echo $'\U1F517 View pinned: https://github.com/emacs-mirror/emacs/commit/'"''${PINNED_COMMIT}"

      # Compare with current overlay commit
      if [[ -n "''${CURRENT_OVERLAY_COMMIT}" ]]; then
        if [[ "''${PINNED_COMMIT}" == "''${CURRENT_OVERLAY_COMMIT}" ]]; then
          echo $'\U2705 Pin matches current overlay commit'
        else
          echo $'\U26A0\UFE0F Pin differs from current overlay commit'
          echo "   Run: emacs-pin (without arguments) to pin to current overlay commit"
          echo "   Run: emacs-unpin to use latest overlay commit"
        fi
      fi

      if [[ -f "''${HASH_FILE}" ]]; then
        STORED_HASH=$(cat "''${HASH_FILE}")
        echo $'\U1F511 Stored hash: '"''${STORED_HASH}"
      else
        echo $'\U26A0\UFE0F Warning: No hash file found - pinning may not work correctly'
        echo "   Run: emacs-pin ''${PINNED_COMMIT} to fix"
      fi
    else
      echo $'\U1F513 emacs-git is not pinned (using latest from overlay)'
      if [[ -n "''${CURRENT_OVERLAY_COMMIT}" ]]; then
        echo "   Run: emacs-pin (without arguments) to pin to current overlay commit"
      fi
    fi

    # Show current emacs version if available
    if command -v emacs >/dev/null 2>&1; then
      echo ""
      echo "Current emacs version:"
      emacs --version | head -1
    fi
  '';

in {
  inherit configuredEmacs;
  pinTools = [ emacsPin emacsUnpin emacsPinDiff emacsPinStatus ];
}
