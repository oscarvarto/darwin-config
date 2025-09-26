{
  pkgs,
  user,
  inputs,
  hostname,
  ...
}: let
  # Emacs pinning system with hash management
  pinFile = "/Users/${user}/.cache/emacs-git-pin";
  hashFile = "/Users/${user}/.cache/emacs-git-pin-hash";
  storePathFile = "/Users/${user}/.cache/emacs-git-store-path";

  # If pinned, and we have a previously built configuredEmacs store path
  # that still exists, prefer re-exporting that path to avoid rebuilds
  storedPathString =
    if builtins.pathExists storePathFile
    then builtins.replaceStrings ["\n"] [""] (builtins.readFile storePathFile)
    else null;
  storedPathValue =
    if storedPathString != null
    then let
      try = builtins.tryEval (builtins.storePath storedPathString);
    in
      if try.success
      then try.value
      else null
    else null;

  # Shared shell helpers for pinning scripts
  commonHelpers = pkgs.writeText "emacs-pinning-common.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail

    pin_resolve_config_path() {
      local script_dir
      script_dir="$(cd "$(dirname "''${BASH_SOURCE[0]:-$0}")" && pwd -P)"
      local candidates=()
      if [[ -n "''${DARWIN_CONFIG_PATH:-}" ]]; then
        candidates+=("''${DARWIN_CONFIG_PATH}")
      fi
      candidates+=(
        "''${HOME}/darwin-config"
        "/Users/''${USER}/darwin-config"
        "''${PWD}"
        "''${script_dir}"
      )
      local d="''${script_dir}"
      for _ in 1 2 3 4 5 6; do
        candidates+=("''${d}")
        d="$(dirname "''${d}")"
      done
      for path in "''${candidates[@]}"; do
        if [[ -n "''${path}" && -f "''${path}/flake.nix" ]]; then
          echo "''${path}"
          return 0
        fi
      done
      return 1
    }

    pin_extract_current_emacs_commit() {
      local config_path="''${1:-}"
      if [[ -z "''${config_path}" ]]; then
        config_path="$(pin_resolve_config_path)" || return 1
      fi
      ( cd "''${config_path}" && nix eval --raw --impure --expr 'let flake = builtins.getFlake (toString ./.); em = flake.inputs.emacs-overlay.packages."${pkgs.stdenv.hostPlatform.system}".emacs-git; in em.src.rev' )
    }

    pin_extract_current_emacs_src_outpath() {
      local config_path="''${1:-}"
      if [[ -z "''${config_path}" ]]; then
        config_path="$(pin_resolve_config_path)" || return 1
      fi
      ( cd "''${config_path}" && nix eval --raw --impure --expr 'let flake = builtins.getFlake (toString ./.); em = flake.inputs.emacs-overlay.packages."${pkgs.stdenv.hostPlatform.system}".emacs-git; in em.src.outPath' )
    }

    pin_extract_current_emacs_hash_sri() {
      local config_path="''${1:-}"
      local out_path
      out_path="$(pin_extract_current_emacs_src_outpath "''${config_path:-}")" || return 1
      nix hash path --type sha256 "''${out_path}" 2>/dev/null
    }

    pin_sri_from_base32() {
      nix hash to-sri --type sha256 "''${1}" 2>/dev/null
    }

    pin_extract_configured_emacs_outpath() {
      # Extract the outPath of the configuredEmacs package exposed by this flake
      # We rely on the hostname to reference the exported package name
      local config_path="''${1:-}"
      if [[ -z "''${config_path}" ]]; then
        config_path="$(pin_resolve_config_path)" || return 1
      fi
      ( cd "''${config_path}" \
        && nix eval --raw --impure --expr 'let flake = builtins.getFlake (toString ./.); in flake.packages."${pkgs.stdenv.hostPlatform.system}"."${hostname}-configuredEmacs".outPath' )
    }
  '';

  isPinned = builtins.pathExists pinFile;

  pinnedCommit =
    if isPinned
    then builtins.replaceStrings ["\n"] [""] (builtins.readFile pinFile)
    else null;

  pinnedHash =
    if isPinned && builtins.pathExists hashFile
    then builtins.replaceStrings ["\n"] [""] (builtins.readFile hashFile)
    else null;

  # Base emacs derivation: pinned (fixed src) or latest overlay
  baseOverlayEmacs = inputs.emacs-overlay.packages.${pkgs.stdenv.hostPlatform.system}.emacs-git;
  emacsPackage =
    if isPinned && pinnedCommit != null && pinnedHash != null
    then
      baseOverlayEmacs.overrideAttrs (old: rec {
        pname = "emacs-git-pinned";
        version = "31.0.50-${builtins.substring 0 7 pinnedCommit}";
        name = "${pname}-${version}";
        src = pkgs.fetchFromGitHub {
          owner = "emacs-mirror";
          repo = "emacs";
          rev = pinnedCommit;
          hash = pinnedHash;
        };
        __pinnedCommit = pinnedCommit;
      })
    else baseOverlayEmacs;

  # Apply emacs configuration overrides with verbose build output
  emacsBase =
    (emacsPackage.override {
      # Native compilation: ESSENTIAL for performance - always enable
      withNativeCompilation = true;

      # Tree-sitter: Likely enabled by default in emacs-git, but ensure it's on
      withTreeSitter = true;

      # Lightweight additions that don't significantly impact build time
      withSQLite3 = true; # Useful for org-roam, org-mode features
      withWebP = true; # Modern image format support

      # Heavy dependencies - only enable if you actually use these features:
      withImageMagick = true;
      withXwidgets = true;
    }).overrideAttrs (oldAttrs: {
      # Add custom icon integration
      postInstall = ''
        ${oldAttrs.postInstall or ""}

        # Integrate custom Emacs icon used across the repo (also used by Raycast)
        # Keep a single source of truth under stow/ so Dock and Raycast match
        CUSTOM_ICON_SOURCE="${../stow/nix-scripts/.local/share/img/icons/Emacs.icns}"
        if [[ -f "$CUSTOM_ICON_SOURCE" ]]; then
          echo "🎨 Integrating custom curvy-blender Emacs icon..."

          # Find the Emacs.app bundle in the output
          EMACS_APP=$(find "$out" -name "Emacs.app" -type d | head -1)
          if [[ -n "$EMACS_APP" && -d "$EMACS_APP/Contents/Resources" ]]; then
            # Backup original icon
            if [[ -f "$EMACS_APP/Contents/Resources/Emacs.icns" ]]; then
              cp "$EMACS_APP/Contents/Resources/Emacs.icns" "$EMACS_APP/Contents/Resources/Emacs.icns.original"
            fi

            # Install custom icon
            cp "$CUSTOM_ICON_SOURCE" "$EMACS_APP/Contents/Resources/Emacs.icns"
            echo "✅ Custom icon installed: $EMACS_APP/Contents/Resources/Emacs.icns"
          else
            echo "⚠️  Could not find Emacs.app bundle or Resources directory"
          fi
        elif [[ ! -f "$CUSTOM_ICON_SOURCE" ]]; then
          echo "ℹ️  Custom icon not found at: $CUSTOM_ICON_SOURCE"
        else
          echo "ℹ️  Not a GUI Emacs build, skipping icon installation"
        fi
      '';

      # Ensure build logs are preserved and visible
      meta =
        (oldAttrs.meta or {})
        // {
          description = "GNU Emacs with enhanced build progress indicators";
          longDescription = ''
            GNU Emacs text editor with native compilation and comprehensive feature set.
            This build includes verbose progress indicators to track compilation status.
            Build typically takes 20-45 minutes with native compilation enabled.
          '';
        };
    });

  # Build Emacs with prebuilt vterm (no runtime compilation) and keep .app bundle
  configuredEmacs =
    if isPinned && storedPathValue != null
    then
      # Fast path: reuse previously built configuredEmacs store path to avoid rebuilds
      pkgs.runCommand "emacs-git-with-packages-reuse-${builtins.substring 0 7 pinnedCommit}" {
        preferLocalBuild = true;
        allowSubstitutes = false;
      } ''
        ln -s ${storedPathValue} "$out"
      ''
    else let
      epkgs = pkgs.emacsPackagesFor emacsBase;
      withPkgs = epkgs.emacsWithPackages (p: [p.vterm]);
    in
      withPkgs.overrideAttrs (old: {
        postInstall = ''
          ${old.postInstall or ""}
          # Ensure the Emacs.app bundle is available from the base build
          if [ -d ${emacsBase}/Applications ]; then
            mkdir -p "$out/Applications"
            ln -s ${emacsBase}/Applications/Emacs.app "$out/Applications/Emacs.app" || true
          fi
        '';
      });

  emacsPin = pkgs.writeScriptBin "emacs-pin" ''
    #!/usr/bin/env bash
    # Pin emacs-git to current nix-provided commit (no args) or specified commit

    set -euo pipefail

    COMMIT="''${1:-}"
    CACHE_DIR="''${HOME}/.cache"
    PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
    HASH_FILE="''${CACHE_DIR}/emacs-git-pin-hash"
    STORE_FILE="''${CACHE_DIR}/emacs-git-store-path"

    # Get hostname from system or use current
    HOSTNAME="${hostname}"

    # Create cache directory if it doesn't exist
    mkdir -p "''${CACHE_DIR}"

    # Load shared helpers
    # shellcheck source=/dev/null
    . "${commonHelpers}"

    # Wrapper to common helper
    extract_current_emacs_commit() { pin_extract_current_emacs_commit "$@"; }

    # Wrapper to common helper (SRI)
    extract_current_emacs_hash() { pin_extract_current_emacs_hash_sri "$@"; }

    # Wrapper to extract configuredEmacs outPath from this flake
    extract_configured_emacs_outpath() { pin_extract_configured_emacs_outpath "$@"; }

    # If no commit hash provided, extract from current emacs
    if [[ -z "''${COMMIT}" ]]; then
      echo $'\U1F4A1 No commit hash provided. Extracting from current emacs overlay...'

      if COMMIT=$(extract_current_emacs_commit); then
        echo $'\U2705 Found current commit: '"''${COMMIT}"

        # Check if already pinned to this commit
        if [[ -f "''${PIN_FILE}" ]]; then
          EXISTING_COMMIT=$(cat "''${PIN_FILE}")
          if [[ "''${EXISTING_COMMIT}" == "''${COMMIT}" ]]; then
            echo $'\U2139\UFE0F Already pinned to current overlay commit: '"''${COMMIT}"
            echo $'\U1F4A1 No rebuild necessary - configuration already matches pin'
            exit 0
          fi
        fi

        # Try to extract the corresponding hash as well
        if HASH=$(extract_current_emacs_hash); then
          echo $'\U2705 Found current hash: '"''${HASH}"

          # Capture the current configuredEmacs outPath BEFORE changing pin state
          # This preserves the exact already-built store path, avoiding rebuilds later.
          CURRENT_OUT_PATH=""
          if CURRENT_OUT_PATH=$(extract_configured_emacs_outpath 2>/dev/null); then
            # Resolve to the real path if it's a symlink (avoid storing wrapper path)
            if [[ -n "''${CURRENT_OUT_PATH}" && -L "''${CURRENT_OUT_PATH}" ]]; then
              CURRENT_OUT_PATH="$(realpath -P "''${CURRENT_OUT_PATH}" 2>/dev/null || echo "''${CURRENT_OUT_PATH}")"
            fi
          fi

          # Save both commit and hash
          echo "''${COMMIT}" > "''${PIN_FILE}"
          echo "''${HASH}" > "''${HASH_FILE}"

          echo $'\U1F4CC Pinned emacs-git to current commit: '"''${COMMIT}"
          echo $'\U1F511 Stored hash (SRI): '"''${HASH}"
          # Save the previously-built outPath if it exists
          if [[ -n "''${CURRENT_OUT_PATH}" && -e "''${CURRENT_OUT_PATH}" ]]; then
            echo "''${CURRENT_OUT_PATH}" > "''${STORE_FILE}"
            echo $'\U1F4E6 Saved built path: '"''${CURRENT_OUT_PATH}"
          else
            echo $'\U2139\UFE0F Could not resolve an existing configuredEmacs outPath at pin time (will build if needed)'
          fi
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

    # Use system-installed nix-prefetch-github to fetch or compute hash
    HASH_RESULT=$(nix-prefetch-github emacs-mirror emacs --rev "''${COMMIT}" 2>/dev/null || true)
    HASH=$(echo "''${HASH_RESULT}" | grep '"hash"' | sed 's/.*"hash": "\([^"]*\)".*/\1/' || true)

    # Fallback if only base32 sha256 is provided
    if [[ -z "''${HASH}" || "''${HASH}" == "null" ]]; then
      BASE32_HASH=$(echo "''${HASH_RESULT}" | grep '"sha256"' | sed 's/.*"sha256": "\([^"]*\)".*/\1/' || true)
      if [[ -n "''${BASE32_HASH}" && "''${BASE32_HASH}" != "null" ]]; then
        if HASH=$(pin_sri_from_base32 "''${BASE32_HASH}"); then
          :
        else
          HASH=""
        fi
      fi
    fi

    if [[ -z "''${HASH}" || "''${HASH}" == "null" ]]; then
      echo $'\U274C Failed to fetch hash for commit '"''${COMMIT}"
      echo "   Please check that the commit exists in the emacs-mirror/emacs repository."
      exit 1
    fi

    # Save the commit hash and its corresponding SHA256
    echo "''${COMMIT}" > "''${PIN_FILE}"
    echo "''${HASH}" > "''${HASH_FILE}"
    # Attempt to capture a currently existing configuredEmacs outPath
    if OUT_PATH=$(extract_configured_emacs_outpath 2>/dev/null) && [[ -e "''${OUT_PATH}" ]]; then
      # Resolve to the actual target if a symlink
      if [[ -L "''${OUT_PATH}" ]]; then
        OUT_PATH="$(realpath -P "''${OUT_PATH}" 2>/dev/null || echo "''${OUT_PATH}")"
      fi
      echo "''${OUT_PATH}" > "''${STORE_FILE}"
      echo $'\U1F4E6 Saved built path: '"''${OUT_PATH}"
    fi

    echo $'\U1F4CC Pinned emacs-git to commit: '"''${COMMIT}"
    echo $'\U1F511 Stored hash (SRI): '"''${HASH}"
    echo $'\U1F4A1 Rebuild your configuration: nb && ns'
  '';

  emacsUnpin = pkgs.writeScriptBin "emacs-unpin" ''
    #!/usr/bin/env bash
    # Unpin emacs-git to use latest commit

    set -euo pipefail

    CACHE_DIR="''${HOME}/.cache"
    PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
    HASH_FILE="''${CACHE_DIR}/emacs-git-pin-hash"
    STORE_FILE="''${CACHE_DIR}/emacs-git-store-path"

    if [[ -f "''${PIN_FILE}" ]]; then
      PINNED_COMMIT=$(cat "''${PIN_FILE}")
      rm "''${PIN_FILE}"
      [[ -f "''${HASH_FILE}" ]] && rm "''${HASH_FILE}"
      [[ -f "''${STORE_FILE}" ]] && rm "''${STORE_FILE}"
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

    # Get hostname from system or use current
    HOSTNAME="${hostname}"

    # Load shared helpers and wrap
    # shellcheck source=/dev/null
    . "${commonHelpers}"
    extract_current_emacs_commit() { pin_extract_current_emacs_commit "$@"; }

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
    STORE_FILE="''${CACHE_DIR}/emacs-git-store-path"

    # Get hostname from system or use current
    HOSTNAME="${hostname}"

    # Load shared helpers and wrap
    # shellcheck source=/dev/null
    . "${commonHelpers}"
    extract_current_emacs_commit() { pin_extract_current_emacs_commit "$@"; }

    # Get current overlay commit for comparison
    CURRENT_OVERLAY_COMMIT=""
    if CURRENT_OVERLAY_COMMIT=$(extract_current_emacs_commit 2>/dev/null); then
      echo $'\U1F4C8 Current overlay emacs-git commit: '"''${CURRENT_OVERLAY_COMMIT}"
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
        echo $'\U1F511 Stored hash (SRI): '"''${STORED_HASH}"
      else
        echo $'\U26A0\UFE0F Warning: No hash file found - pinning may not work correctly'
        echo "   Run: emacs-pin ''${PINNED_COMMIT} to fix"
      fi

      if [[ -f "''${STORE_FILE}" ]]; then
        STORED_PATH=$(cat "''${STORE_FILE}")
        echo $'\U1F4E6 Stored build path: '"''${STORED_PATH}"
      else
        echo $'\U26A0\UFE0F Stored build path not found (likely GC\'d)'
        echo "   Behavior: will build latest overlay commit and auto-pin to it after switch"
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
  pinTools = [emacsPin emacsUnpin emacsPinDiff emacsPinStatus];
}
