{
  config,
  lib,
  pkgs,
  pathConfig ? null,
  darwinConfigPath,
  ...
}: let
  cfg = config.local.xonsh;

  # Read the base xonsh configuration
  baseXonshConfig = builtins.readFile ./rc.xsh;

  # Pre-packaged xontribs resolved via Nix.
  packagedXontribs = import ./xontrib-packages.nix {inherit lib pkgs;};

  # Generate PATH configuration for xonsh using centralized module output
  pathConfigXonsh =
    if pathConfig != null
    then pathConfig.xonsh.pathSetup
    else ''
      # Centralized PATH configuration not available
      print("Warning: PATH configuration not available")
    '';

  xontribsList = cfg.xontribs;
  xontribsJson = builtins.toJSON xontribsList;

  builtInXontribs = ["coreutils"];

  normalizePackageName = name: let
    withoutXontrib =
      if lib.hasPrefix "xontrib-" name
      then lib.removePrefix "xontrib-" name
      else name;
    withoutXonsh =
      if lib.hasPrefix "xonsh-" withoutXontrib
      then lib.removePrefix "xonsh-" withoutXontrib
      else withoutXontrib;
  in
    withoutXonsh;

  resolvePackaged = name: let
    normalized = normalizePackageName name;
    byNormalized = lib.attrByPath [normalized] null packagedXontribs;
  in
    if byNormalized != null
    then byNormalized
    else lib.attrByPath [name] null packagedXontribs;

  resolvedXontribPackages =
    lib.filter (pkg: pkg != null)
    (map resolvePackaged xontribsList);

  extraPackageNames = cfg.extraPipPackages;
  resolvedExtraPackages =
    lib.filter (pkg: pkg != null)
    (map resolvePackaged extraPackageNames);

  missingPackagedXontribs =
    lib.filter (name: (resolvePackaged name) == null && !(lib.elem name builtInXontribs))
    (lib.unique (xontribsList ++ extraPackageNames));

  # Generate darwin-specific aliases
  darwinAliases = ''
    # =============================================================================
    # Darwin Configuration Aliases
    # =============================================================================

    # Darwin-rebuild aliases
    aliases['nb'] = 'nix run ${darwinConfigPath}#build --'
    aliases['ns'] = 'nix run ${darwinConfigPath}#build-switch --'

    # Set darwin config path
    $DARWIN_CONFIG_PATH = "${darwinConfigPath}"
  '';

  envSetup = ''
    # =============================================================================
    # Environment Variables
    # =============================================================================

    $XONTRIBS_TO_LOAD = ${xontribsJson}
  '';

  generatedConfigParts =
    [baseXonshConfig]
    ++ lib.optionals (pathConfigXonsh != "") [pathConfigXonsh]
    ++ [envSetup]
    ++ [darwinAliases]
    ++ lib.optionals (cfg.extraConfig != "") [cfg.extraConfig];

  xontribsLoadSection = lib.optionalString (xontribsList != []) ''
    # =============================================================================
    # Xontrib Configuration (Generated)
    # =============================================================================

    try:
        for xontrib in $XONTRIBS_TO_LOAD:
            try:
                xontrib load @(xontrib)
            except Exception as exc:
                # Suppress warnings for known working xontribs that have health check issues
                if xontrib in ['carapace-bin', 'starship']:
                    pass  # These xontribs work despite health check warnings
                else:
                    print(f"Warning: Could not load xontrib '{xontrib}': {exc}")
    except Exception as exc:
        print(f"Warning: Error in xontrib loading: {exc}")
  '';

  # Combine all configuration parts
  fullXonshConfig =
    lib.concatStringsSep "\n\n"
    (generatedConfigParts ++ lib.optional (xontribsLoadSection != "") xontribsLoadSection);

  # ~/.xonshrc should omit the load section to avoid double loading
  baseXonshRcText = lib.concatStringsSep "\n\n" generatedConfigParts;
in {
  options.local.xonsh = {
    enable = lib.mkEnableOption "custom xonsh configuration";

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration to add to xonshrc";
    };

    xontribs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        # Core functionality
        "coreutils"
        "sh" # Essential for bash/zsh command compatibility

        # Tab completions
        "argcomplete" # Bash-style argument completion
        "carapace-bin" # Multi-shell completion engine

        # Directory navigation
        "zoxide" # Smart directory jumping

        # Prompts
        "starship" # Cross-shell prompt

        # Integration
        "kitty" # Kitty terminal integration
        "homebrew" # Homebrew integration
        "1password" # 1Password CLI integration

        # Useful plugins
        "clp" # Clipboard integration
        "pipeliner" # Pipeline utilities
      ];
      description = "List of xontribs to load";
    };

    extraPipPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["cheatsheet"];
      description = ''
        Additional packaged xontribs (by logical name) to bundle with the xonsh Python environment.
        Legacy option name retained for compatibility; values are resolved via modules/xonsh/xontrib-packages.nix.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      []
      ++ lib.optionals (lib.elem "starship" xontribsList) [pkgs.starship]
      ++ lib.optionals (lib.elem "carapace-bin" xontribsList) [pkgs.carapace]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        # macOS-specific packages for better terminal support
        pkgs.terminal-notifier
      ];

    assertions = [
      {
        assertion = missingPackagedXontribs == [];
        message =
          "The following xontribs are not yet packaged in modules/xonsh/xontrib-packages.nix: "
          + lib.concatStringsSep ", " missingPackagedXontribs;
      }
    ];

    # Xonsh configuration file
    xdg.configFile."xonsh/rc.xsh" = {
      text = fullXonshConfig;
    };

    # Create ~/.xonshrc with the same content (xonsh looks for this by default)
    home.file.".xonshrc" = {
      text = baseXonshRcText;
    };

    # Completion support
    xdg.configFile."xonsh/completions".source = let
      completions = pkgs.runCommand "xonsh-completions" {} ''
        mkdir -p $out
        # Add custom completions here if needed
        touch $out/.keep
      '';
    in
      completions;
  };
}
