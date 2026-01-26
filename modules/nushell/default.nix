{
  config,
  pkgs,
  lib,
  inputs,
  pathConfig ? null,
  darwinConfigPath ? "",
  ...
}: let
  cfg = config.local.nushell;
  inherit (lib) mkEnableOption mkIf;

  # Secrets loader for nushell (parses LazyVim secrets.lua)
  # Uses double quotes for regex so escape sequences are interpreted correctly
  secretsFile = "${darwinConfigPath}/stow/lazyvim/.config/nvim/secrets.lua";
  nushellSecretsLoader = ''
    # Load API keys from LazyVim secrets.lua (not tracked in git)
    if ("${secretsFile}" | path exists) {
      let secrets_to_load = (open "${secretsFile}"
        | lines
        | each { |line|
            # Note: Using double quotes so \\s becomes \s in the regex
            let match = ($line | parse --regex "^\\s*(?P<key>[A-Z_][A-Z0-9_]*)\\s*=\\s*\"(?P<value>.*)\"\\s*,?\\s*$")
            if ($match | is-not-empty) {
              let entry = ($match | first)
              { ($entry.key): $entry.value }
            } else {
              null
            }
          }
        | compact
        | reduce --fold {} { |it, acc| $acc | merge $it })
      load-env $secrets_to_load
    }
  '';
in {
  options.local.nushell = {
    enable = mkEnableOption "nushell";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nushell;
      description = "The nushell package to use";
    };
    left_prompt_cmd = lib.mkOption {
      default = "hostname -s";
      type = lib.types.str;
      description = "Command to use to generate left prompt text";
    };
    history_file_format = lib.mkOption {
      default = "sqlite";
      type = lib.types.str;
      description = "History file format, either sqlite or plaintext";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      nushell = {
        enable = true;
        package = cfg.package;
        configFile.text =
          builtins.replaceStrings [
            "HISTORY_FILE_FORMAT"
            "NIX_BASH_ENV_NU_MODULE"
          ] [
            config.local.nushell.history_file_format
            "${inputs.bash-env-nushell.packages.${pkgs.stdenv.hostPlatform.system}.default}/bash-env.nu"
          ]
          (builtins.readFile ./config.nu);
        envFile.text =
          ''
            # Nushell Environment Config File

            # Nix daemon initialization (equivalent to Fish shell initialization)
            if ('/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' | path exists) {
                $env.NIX_SSL_CERT_FILE = '/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt'
                $env.NIX_PROFILES = '/nix/var/nix/profiles/default ~/.nix-profile'
                $env.NIX_PATH = 'nixpkgs=flake:nixpkgs'
            }

            # Apply centralized PATH configuration from modules/path-config.nix
            ${
              if pathConfig != null
              then pathConfig.nushell.pathSetup
              else "# Centralized PATH config not available"
            }

            # Fix for macOS libcrypto "poisoning" - ensures Nix's OpenSSL is loaded
            # instead of the system's abort()-ing stub (see: https://github.com/NixOS/nixpkgs/issues/160258)
            $env.DYLD_LIBRARY_PATH = '${pkgs.openssl.out}/lib'

            # Ensure Enchant uses aspell and aspell finds Nix-installed dictionaries
            $env.ENCHANT_ORDERING = 'en:aspell,es:aspell,*:aspell'
            $env.ASPELL_CONF = 'dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [en en-computers en-science es])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell'

            ${nushellSecretsLoader}

            def create_left_prompt [] {
                let hostname_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
                $"($hostname_color)(${config.local.nushell.left_prompt_cmd})(ansi reset)"
            }

          ''
          + (builtins.readFile ./env.nu);

        # plugins temporarily disabled due to version compatibility issues
        plugins = with pkgs.nushellPlugins; [
          polars
          gstat
          formats
          query

          # highlight
          # semver
          # units
        ];
      };

      direnv.enableNushellIntegration = true;
    };

    home = {
      packages = with pkgs; [
        inputs.bash-env-json.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.bash-env-nushell.packages.${pkgs.stdenv.hostPlatform.system}.default
        jc
      ];

      # Deploy mise.nu configuration for manual mise integration
      file.".config/nushell/mise.nu".source = ./mise.nu;

      # Deploy opam.nu configuration for OCaml/opam integration
      file.".config/nushell/opam.nu".source = ./opam.nu;
    };

    # Note: pueue service is managed via Homebrew on macOS
  };
}
