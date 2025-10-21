{
  pkgs,
  user,
  inputs,
  hostname,
  darwinConfigPath,
  emacsPinRust,
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

  # Path to external xonsh scripts for pinning tools
  # These scripts live in the same directory as this module (modules/emacs-pinning/)
  # They provide the same functionality as the previous embedded bash scripts,
  # but with better maintainability, no escaping issues, and comprehensive documentation.
  pinScriptsPath = "${./.}";

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
      # Add custom icon integration for macOS 26 Tahoe Liquid Glass icons
      postInstall = ''
        ${oldAttrs.postInstall or ""}

        # Integrate Liquid Glass icons for macOS 26 Tahoe (and fallback for earlier versions)
        # Source: https://github.com/jimeh/emacs-liquid-glass-icons
        ASSETS_CAR_SOURCE="${./.}/assets/icons/Assets.car"
        ICON_LG1_DEFAULT_SOURCE="${./.}/assets/icons/EmacsLG1-Default.icns"
        ICON_LG1_DARK_SOURCE="${./.}/assets/icons/EmacsLG1-Dark.icns"

        # Find the Emacs.app bundle in the output
        EMACS_APP=$(find "$out" -name "Emacs.app" -type d | head -1)
        if [[ -n "$EMACS_APP" && -d "$EMACS_APP/Contents/Resources" ]]; then
          echo "🎨 Integrating Liquid Glass Emacs icons for macOS 26 Tahoe..."

          # Backup original icon (for pre-Tahoe compatibility)
          if [[ -f "$EMACS_APP/Contents/Resources/Emacs.icns" ]]; then
            cp "$EMACS_APP/Contents/Resources/Emacs.icns" "$EMACS_APP/Contents/Resources/Emacs.icns.original"
          fi

          # Install Assets.car for macOS 26 Tahoe (contains all three liquid glass icons)
          if [[ -f "$ASSETS_CAR_SOURCE" ]]; then
            cp "$ASSETS_CAR_SOURCE" "$EMACS_APP/Contents/Resources/Assets.car"
            echo "✅ Assets.car installed for macOS 26 Tahoe support"
          else
            echo "⚠️  Assets.car not found at: $ASSETS_CAR_SOURCE"
          fi

          # Install EmacsLG1-Default.icns as fallback for pre-Tahoe macOS versions
          if [[ -f "$ICON_LG1_DEFAULT_SOURCE" ]]; then
            cp "$ICON_LG1_DEFAULT_SOURCE" "$EMACS_APP/Contents/Resources/Emacs.icns"
            echo "✅ EmacsLG1-Default.icns installed as Emacs.icns (fallback for pre-Tahoe)"
          else
            echo "⚠️  EmacsLG1-Default.icns not found at: $ICON_LG1_DEFAULT_SOURCE"
          fi

          # Update Info.plist to reference EmacsLG1 in Assets.car (for macOS 26 Tahoe)
          if [[ -f "$EMACS_APP/Contents/Info.plist" ]]; then
            # Use PlistBuddy to add/update CFBundleIconName
            /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string 'EmacsLG1'" "$EMACS_APP/Contents/Info.plist" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Set :CFBundleIconName 'EmacsLG1'" "$EMACS_APP/Contents/Info.plist"
            echo "✅ Info.plist updated: CFBundleIconName = EmacsLG1"
          else
            echo "⚠️  Info.plist not found in: $EMACS_APP/Contents/"
          fi

          echo "✅ Liquid Glass icon integration complete!"
        else
          echo "⚠️  Could not find Emacs.app bundle or Resources directory"
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

  # Rust implementation wrappers - primary option (fast, compiled)
  # These wrap the Rust binary to provide individual commands matching xonsh interface
  emacsPinRs = pkgs.writeScriptBin "emacs-pin-rs" ''
    #!/usr/bin/env bash
    exec ${emacsPinRust}/bin/emacs-pin pin "$@"
  '';

  emacsUnpinRs = pkgs.writeScriptBin "emacs-unpin-rs" ''
    #!/usr/bin/env bash
    exec ${emacsPinRust}/bin/emacs-pin unpin "$@"
  '';

  emacsPinDiffRs = pkgs.writeScriptBin "emacs-pin-diff-rs" ''
    #!/usr/bin/env bash
    exec ${emacsPinRust}/bin/emacs-pin diff "$@"
  '';

  emacsPinStatusRs = pkgs.writeScriptBin "emacs-pin-status-rs" ''
    #!/usr/bin/env bash
    exec ${emacsPinRust}/bin/emacs-pin status "$@"
  '';

  # Xonsh implementation wrappers - fallback/reference option
  emacsPin = pkgs.writeScriptBin "emacs-pin" ''
    #!/usr/bin/env bash
    # Wrapper script that calls the external xonsh implementation
    # --no-rc: Skip loading ~/.xonshrc to avoid xontrib warnings in non-interactive mode
    exec ${pkgs.xonsh}/bin/xonsh --no-rc "${pinScriptsPath}/emacs-pin.xsh" "$@"
  '';

  emacsUnpin = pkgs.writeScriptBin "emacs-unpin" ''
    #!/usr/bin/env bash
    # Wrapper script that calls the external xonsh implementation
    # --no-rc: Skip loading ~/.xonshrc to avoid xontrib warnings in non-interactive mode
    exec ${pkgs.xonsh}/bin/xonsh --no-rc "${pinScriptsPath}/emacs-unpin.xsh" "$@"
  '';

  emacsPinDiff = pkgs.writeScriptBin "emacs-pin-diff" ''
    #!/usr/bin/env bash
    # Wrapper script that calls the external xonsh implementation
    # --no-rc: Skip loading ~/.xonshrc to avoid xontrib warnings in non-interactive mode
    exec ${pkgs.xonsh}/bin/xonsh --no-rc "${pinScriptsPath}/emacs-pin-diff.xsh" "$@"
  '';

  emacsPinStatus = pkgs.writeScriptBin "emacs-pin-status" ''
    #!/usr/bin/env bash
    # Wrapper script that calls the external xonsh implementation
    # --no-rc: Skip loading ~/.xonshrc to avoid xontrib warnings in non-interactive mode
    exec ${pkgs.xonsh}/bin/xonsh --no-rc "${pinScriptsPath}/emacs-pin-status.xsh" "$@"
  '';
in {
  inherit configuredEmacs;
  # Export both Rust (primary) and xonsh (fallback) tools
  pinTools = [
    # Rust tools (preferred - fast, no runtime dependencies)
    emacsPinRs
    emacsUnpinRs
    emacsPinDiffRs
    emacsPinStatusRs
    # Xonsh tools (fallback - for reference/compatibility)
    emacsPin
    emacsUnpin
    emacsPinDiff
    emacsPinStatus
  ];
}
