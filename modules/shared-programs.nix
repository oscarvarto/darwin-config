{
  config,
  pkgs,
  lib,
  user ? "oscarvarto",
  userConfig ? {
    name = user;
    email = "${user}@example.com";
    workDir = "dev";
  },
  ...
}: let
  name = userConfig.name;
  # user is passed as parameter
  shellConfig = import ./shell-config.nix {inherit config pkgs lib;};
  gitIgnores = import ./git-ignores.nix {inherit config pkgs lib;};
  gitSecurityScripts = import ./git-security-scripts.nix {inherit config pkgs lib user;};
in {
  # Import git security scripts
  imports = [./git-security-scripts.nix];
  # Merge shell configurations directly (flatten)
  programs =
    shellConfig.programs
    // {
      git = {
        enable = true;
        ignores = gitIgnores.git.ignores;
        # userName and userEmail are handled by conditional includes based on directory
        lfs = {
          enable = false;
        };
        extraConfig = {
          init.defaultBranch = "main";
          core = {
            editor = "nvim";
            autocrlf = false; # Better for macOS - preserves line endings as-is
            eol = "lf"; # Use LF line endings on macOS
            ignorecase = false; # Case-sensitive file names
            # hooksPath removed - now configured conditionally
          };
          commit.gpgsign = false;
          diff.colorMoved = "zebra"; # https://spin.atomicobject.com/git-configurations-default/
          fetch.prune = true;
          pull.rebase = true;
          push.autoSetupRemote = true;
          rebase.autoStash = true;
          safe.directory = [
            "*" # Trust all directories (most comprehensive)
            "/Users/${user}/darwin-config"
            "/nix/store/*"
            "/opt/homebrew/*"
          ];
          # Conditional includes for work directory
          includeIf."gitdir:/Users/${user}/work/**".path = "/Users/${user}/.config/git/config-work";
          # Include personal config as fallback for all other directories
          include.path = "/Users/${user}/.config/git/config-personal";
        };
      };

      ssh = {
        enable = true;
        includes = [
          "/Users/${user}/.ssh/config_external"
        ];
        matchBlocks = {
          "github.com" = {
            identitiesOnly = true;
            identityFile = [
              "/Users/${user}/.ssh/id_ed25519"
            ];
          };
        };
      };
    };
}
