{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.local.nushell;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.local.nushell = {
    enable = mkEnableOption "nushell";
    left_prompt_cmd = lib.mkOption { default = "hostname -s"; type = lib.types.str; description = "Command to use to generate left prompt text"; };
    history_file_format = lib.mkOption { default = "sqlite"; type = lib.types.str; description = "History file format, either sqlite or plaintext"; };
  };

  config = mkIf cfg.enable {
    programs = {
      nushell = {
        enable = true;
        configFile.text = (builtins.replaceStrings [
          "HISTORY_FILE_FORMAT"
          "NIX_BASH_ENV_NU_MODULE"
        ] [
          config.local.nushell.history_file_format
          "${inputs.bash-env-nushell.packages.${pkgs.system}.default}/bash-env.nu"
        ]
          (builtins.readFile ./config.nu));
        envFile.text = ''
          # Nushell Environment Config File

          # Nix daemon initialization (equivalent to Fish shell initialization)
          if ('/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' | path exists) {
              $env.NIX_SSL_CERT_FILE = '/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt'
              $env.NIX_PROFILES = '/nix/var/nix/profiles/default ~/.nix-profile'
              $env.NIX_PATH = '/nix/var/nix/profiles/per-user/root/channels'
              $env.PATH = ($env.PATH | split row (char esep) | prepend '/nix/var/nix/profiles/default/bin' | uniq | str join (char esep))
          }

          def create_left_prompt [] {
              let hostname_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
              $"($hostname_color)(${config.local.nushell.left_prompt_cmd})(ansi reset)"
          }

        '' + (builtins.readFile ./env.nu);
      };

      direnv.enableNushellIntegration = true;
    };

    home = {
      packages = with pkgs; [
        inputs.bash-env-json.packages.${pkgs.system}.default
        inputs.bash-env-nushell.packages.${pkgs.system}.default
        jc
      ];
    };

    # pueue service is only available on Linux via home-manager
    # On macOS we use the Homebrew version
    services.pueue.enable = pkgs.stdenv.hostPlatform.isLinux;
  };
}
