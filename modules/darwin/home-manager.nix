{ config, pkgs, catppuccin, neovim-nightly-overlay, nixd-ls, op-shell-plugins, user ? "oscarvarto", ... } @ inputs:

let
  sharedFiles = import ../shared/files.nix { inherit config pkgs user; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
  inherit (builtins) fromTOML;

  # Custom nushell 0.106.0 built from source
  # nushell-custom = pkgs.nushell.overrideAttrs (oldAttrs: rec {
  #   version = "0.106.0";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "nushell";
  #     repo = "nushell";
  #     rev = "0.106.0";
  #     hash = "sha256-kFDbLt/1rB+8aqNulc0Wm6ZcMa2VXRPYvu0NFLoYCNQ=";
  #   };
  #   # Let Nix automatically handle cargo dependencies for the new source
  #   cargoDeps = pkgs.rustPlatform.importCargoLock {
  #     lockFile = "${src}/Cargo.lock";
  #   };
  # });

  # TODO: Build custom nushell plugins from the same source
  # For now, we'll install them manually using cargo to avoid complexity
in
{

  imports = [
    ./dock
    ./brews.nix
    ./window-manager.nix
    ./zsh-darwin.nix
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = "/Users/${user}/.nix-profile/bin/nu";
  };

  environment.variables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    BAT_THEME="ansi";
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${user} = { pkgs, config, lib, ... }: {
      imports = [
        ../shared/nushell
        ../shared/home-manager.nix
        catppuccin.homeModules.catppuccin
        op-shell-plugins.hmModules.default
      ];

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = (pkgs.callPackage ./packages.nix {}) ++ [
          # Add neovim-nightly from overlay
          neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim
          # TODO: Add custom nushell plugins when building is resolved
          nixd-ls.packages.${pkgs.stdenv.hostPlatform.system}.nixd
        ];
        file = lib.mkMerge [
          sharedFiles
          additionalFiles
        ];

        stateVersion = "25.05";
      };

      catppuccin.flavor = "mocha";
      catppuccin.enable = true;

      programs = {
        _1password-shell-plugins = {
          # enable 1Password shell plugins for bash, zsh
          enable = true;
          # the specified packages as well as 1Password CLI will be
          # automatically installed and configured to use shell plugins
          plugins = with pkgs; [ awscli cachix gh glab ];
        };

        atuin = {
          enable = true;
          daemon.enable = true;
          enableNushellIntegration = false;
          enableZshIntegration = true;
        };

        helix.enable = true;

        jujutsu = {
          enable = true;
          settings = {
            ui.editor = "nvim";
            user = {
              email = "contact@oscarvarto.mx";
              name = "Oscar Vargas Torres";
            };
          };
        };

        mise = {
          enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
        };

        starship = {
          enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
          settings = fromTOML(builtins.readFile ./starship.toml);
        };

        vscode = {
          enable = true;
          mutableExtensionsDir = true;
        };

        yazi = {
          enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
          settings = {
            mgr = {
              ratio = [1 3 4];
            };
          };
        };

        zoxide = {
          enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
        };

        # zellij is installed via homebrew and configured manually
        # We use external config file instead of home-manager settings
      };

      # Enable nushell via shared module with custom 0.106.0 package
      local = {
        nushell = {
          enable = true;
        };
      };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        { path = "/Applications/Emacs.app/"; }
        { path = "/Applications/Zed Preview.app/"; }
        { path = "/Applications/Ghostty.app/"; }
        { path = "/Applications/WarpPreview.app/"; }
        { path = "/Applications/Zen.app/"; }
        { path = "/Applications/Safari.app/"; }
        { path = "/Applications/Microsoft Teams.app/"; }
        { path = "/Applications/Microsoft Outlook.app/"; }
        { path = "/Applications/Parallels Desktop.app/"; }
        { path = "/Applications/Beekeeper Studio.app/"; }
        { path = "/System/Applications/Music.app/"; }
        { path = "/System/Applications/Calendar.app/"; }
        { path = "/System/Applications/System Settings.app/"; }
      ];
    };
  };
}
