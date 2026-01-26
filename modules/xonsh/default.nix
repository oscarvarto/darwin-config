{
  config,
  lib,
  pkgs,
  inputs ? {},
  pathConfig ? null,
  darwinConfigPath,
  ...
}: let
  cfg = config.local.xonsh;

  # Read the base xonsh configuration
  baseXonshConfig = builtins.readFile ./rc.xsh;

  # Tree-sitter grammar for xonsh (from the forked repository)
  xonshGrammarSrc =
    if inputs ? tree-sitter-xonsh
    then inputs.tree-sitter-xonsh
    else pkgs.tree-sitter.grammars.python.src;

  xonshGrammarVersion =
    if inputs ? tree-sitter-xonsh
    then (lib.importJSON "${inputs.tree-sitter-xonsh}/tree-sitter.json").metadata.version
    else pkgs.tree-sitter.grammars.python.version;

  xonshGrammar = pkgs.tree-sitter.buildGrammar {
    language = "xonsh";
    version = xonshGrammarVersion;
    src = xonshGrammarSrc;
  };

  xonshGrammarExt =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "dylib"
    else "so";

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

  # Secrets loader for xonsh (parses LazyVim secrets.lua)
  secretsFile = "${darwinConfigPath}/stow/lazyvim/.config/nvim/secrets.lua";
  xonshSecretsLoader = ''
    # =============================================================================
    # API Keys from LazyVim secrets.lua (not tracked in git)
    # =============================================================================
    import os as _os
    import re as _re

    _secrets_file = "${secretsFile}"
    if _os.path.exists(_secrets_file):
        try:
            with open(_secrets_file, 'r') as _f:
                _content = _f.read()
            # Parse Lua table format: KEY = "value", or KEY = 'value',
            _pattern = r'^\s*([A-Z_][A-Z0-9_]*)\s*=\s*["\x27](.*)["\x27]\s*,?\s*$'
            for _line in _content.splitlines():
                _match = _re.match(_pattern, _line)
                if _match:
                    _key, _value = _match.groups()
                    # Set as xonsh environment variable
                    __xonsh__.env[_key] = _value
                    # Also set in os.environ for subprocesses
                    _os.environ[_key] = _value
        except Exception as _e:
            print(f"Warning: Could not load secrets: {_e}")
  '';

  # Generate darwin-specific aliases
  darwinAliases = ''
    # =============================================================================
    # Darwin Configuration Aliases
    # =============================================================================

    # Darwin-rebuild aliases
    aliases['nb'] = ['nix', 'run', '${darwinConfigPath}#build', '--']
    aliases['ns'] = ['nix', 'run', '${darwinConfigPath}#build-switch', '--']

    # Set darwin config path
    $DARWIN_CONFIG_PATH = "${darwinConfigPath}"
  '';

  envSetup = ''
    # =============================================================================
    # Environment Variables
    # =============================================================================

    # Fix for macOS libcrypto "poisoning" - ensures Nix's OpenSSL is loaded
    # instead of the system's abort()-ing stub (see: https://github.com/NixOS/nixpkgs/issues/160258)
    $DYLD_LIBRARY_PATH = '${pkgs.openssl.out}/lib'

    $XONTRIBS_TO_LOAD = ${xontribsJson}
  '';

  # Direct tool integration
  toolIntegration = ''
    # =============================================================================
    # Tool Integration (Direct)
    # =============================================================================

    # Starship Integration (disabled in Claude Code - doesn't render truecolor properly)
    import os
    if not os.getenv('CLAUDECODE'):
        try:
            starship_path = $(which starship).strip()
            if starship_path:
                $STARSHIP_CONFIG = str(Path.home() / ".config" / "starship.toml")
                # Initialize starship for xonsh
                execx($(starship init xonsh))
                print("✓ Starship prompt enabled")
        except:
            print("Warning: Starship not found")
    else:
        # Use simple prompt for Claude Code
        import socket
        $PROMPT = lambda: f"{os.getenv('USER', 'user')}@{socket.gethostname().split('.')[0]} {os.getcwd().replace(os.path.expanduser('~'), '~')} > "
        print("✓ Using simple prompt (Claude Code mode)")

    # Zoxide Integration (manual, safer than xontrib)
    try:
        zoxide_path = $(which zoxide).strip()
        if zoxide_path:
            # Initialize zoxide for xonsh
            execx($(zoxide init xonsh), 'exec', __xonsh__.ctx, filename='zoxide')
            # Add cd alias that uses zoxide
            aliases['cd'] = 'z'
            print("✓ Zoxide navigation enabled")
    except:
        print("Warning: Zoxide not found")

    # Atuin Integration
    try:
        import subprocess
        atuin_check = subprocess.run(['which', 'atuin'], capture_output=True, text=True)
        if atuin_check.returncode == 0:
            atuin_path = atuin_check.stdout.strip()
            if atuin_path:
                # Initialize atuin for xonsh - atuin has experimental xonsh support
                execx($(atuin init xonsh))
                print("✓ Atuin history integration enabled")
        else:
            print("Warning: Atuin not found")
    except Exception as e:
        print(f"Warning: Atuin initialization failed: {e}")
  '';

  generatedConfigParts =
    [baseXonshConfig]
    ++ lib.optionals (pathConfigXonsh != "") [pathConfigXonsh]
    ++ [envSetup]
    ++ [xonshSecretsLoader]
    ++ [toolIntegration]
    ++ [darwinAliases]
    ++ lib.optionals (cfg.extraConfig != "") [cfg.extraConfig];

  # Xontrib loading section - relies on pixi environment having the packages installed
  xontribsLoadSection = lib.optionalString (xontribsList != []) ''
    # =============================================================================
    # Xontrib Configuration
    # =============================================================================
    # Note: xontribs are provided by the pixi environment (~/darwin-config/python-env)
    # Run 'pixi install' in that directory if xontribs fail to load

    import sys
    import io
    from contextlib import redirect_stdout, redirect_stderr

    # Entry-point based xontribs (1password, homebrew) trigger false "not installed"
    # warnings during health check, but actually load fine. Suppress output during load.
    _entry_point_xontribs = {'1password', 'homebrew', 'kitty'}

    for xontrib_name in $XONTRIBS_TO_LOAD:
        try:
            if xontrib_name in _entry_point_xontribs:
                # Suppress false warnings for entry-point based xontribs
                _stdout_capture = io.StringIO()
                with redirect_stdout(_stdout_capture), redirect_stderr(_stdout_capture):
                    xontrib load @(xontrib_name)
            else:
                xontrib load @(xontrib_name)

            # Special handling for mise xontrib
            if xontrib_name == "mise":
                try:
                    import xonsh as _xonsh_mod
                    if "xontrib.mise" in sys.modules:
                        sys.modules["xontrib.mise"].xonsh = _xonsh_mod
                except:
                    pass
        except Exception as exc:
            print(f"Warning: Could not load xontrib '{xontrib_name}': {exc}")
  '';

  # Combine all configuration parts
  fullXonshConfig =
    lib.concatStringsSep "\n\n"
    (generatedConfigParts ++ lib.optional (xontribsLoadSection != "") xontribsLoadSection);
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

        # Useful plugins
        "clp" # Clipboard integration
        "pipeliner" # Pipeline utilities
        "cheatsheet" # Xonsh cheatsheet

        # Integrations
        "1password" # 1Password CLI integration
        "homebrew" # Homebrew integration
        "kitty" # Kitty terminal integration
        "mise" # Mise/rtx integration
      ];
      description = ''
        List of xontribs to load. These must be installed in the pixi environment
        (~/darwin-config/python-env/pixi.toml). Run 'pixi install' to install them.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Packages needed for tool integrations (starship, zoxide, atuin are typically in PATH already)
    home.packages = lib.optionals pkgs.stdenv.isDarwin [
      pkgs.terminal-notifier
    ];

    # Xonsh configuration file - single source of truth
    home.file.".xonshrc" = {
      text = fullXonshConfig;
    };

    # Completion support
    xdg.configFile."xonsh/completions".source = let
      completions = pkgs.runCommand "xonsh-completions" {} ''
        mkdir -p $out
        touch $out/.keep
      '';
    in
      completions;

    # Helix runtime queries for xonsh (inherit Python queries + small overrides)
    xdg.configFile."helix/runtime/queries/xonsh/highlights.scm".source =
      ./helix/runtime/queries/xonsh/highlights.scm;
    xdg.configFile."helix/runtime/queries/xonsh/indents.scm".source =
      ./helix/runtime/queries/xonsh/indents.scm;
    xdg.configFile."helix/runtime/queries/xonsh/locals.scm".source =
      ./helix/runtime/queries/xonsh/locals.scm;
    xdg.configFile."helix/runtime/queries/xonsh/injections.scm".source =
      ./helix/runtime/queries/xonsh/injections.scm;
    xdg.configFile."helix/runtime/queries/xonsh/folds.scm".source =
      ./helix/runtime/queries/xonsh/folds.scm;

    # Helix runtime grammar for xonsh
    xdg.configFile."helix/runtime/grammars/xonsh.${xonshGrammarExt}".source = "${xonshGrammar}/parser";
  };
}
