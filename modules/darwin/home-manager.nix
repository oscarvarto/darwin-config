{ config, pkgs, user ? "oscarvarto", ... } @ inputs:

let
  sharedFiles = import ./files.nix { inherit config pkgs; };
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
    # Force Enchant to use aspell and point aspell to the Nix-provided dictionaries
    ENCHANT_ORDERING = "en:aspell,es:aspell,*:aspell";
    ASPELL_CONF = "dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell";
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${user} = { pkgs, config, lib, ... }: {
      imports = [
        ./nushell
        ./git-security-scripts.nix
        inputs.catppuccin.homeModules.catppuccin
        inputs.op-shell-plugins.hmModules.default
      ];

      # Test: re-enable font management now that mise SDK issues are fixed
      # disabledModules = [ "targets/darwin/fonts.nix" ];

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = (pkgs.callPackage ./packages.nix {}) ++ [
          # Add neovim-nightly from overlay
          inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim
          # Add nixd nightly from flake input
          inputs.nixd-ls.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
        file = lib.mkMerge [
          sharedFiles
          additionalFiles
        ];

        # Ensure user shells and GUI apps see Enchant/Aspell settings
        sessionVariables = {
          ENCHANT_ORDERING = "en:aspell,es:aspell,*:aspell";
          ASPELL_CONF = "dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell";
        };

        stateVersion = "25.05";
      };

      # Test: re-enable font management to see if it still causes issues
      fonts.fontconfig.enable = true;

      catppuccin.flavor = "mocha";
      catppuccin.enable = true;

      programs = {
        _1password-shell-plugins = {
          # enable 1Password shell plugins for bash, zsh
          enable = true;
          # the specified packages as well as 1Password CLI will be
          # automatically installed and configured to use shell plugins
          plugins = with pkgs; [ cachix gh glab ];
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
          # Use nixpkgs mise package instead of flake to avoid SDK issues
          # package = inputs.mise.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
        
        # Git configuration
        git = {
          enable = true;
          ignores = (import ./git-ignores.nix { inherit config pkgs lib; }).git.ignores;
          userName = "Oscar Vargas Torres";
          lfs.enable = true;
          extraConfig = {
            init.defaultBranch = "main";
            core = {
              editor = "nvim";
              autocrlf = false;
              eol = "lf";
              ignorecase = false;
            };
            commit.gpgsign = false;
            diff.colorMoved = "zebra";
            fetch.prune = true;
            pull.rebase = true;
            push.autoSetupRemote = true;
            rebase.autoStash = true;
            safe.directory = [
              "*"
              "/Users/${user}/nixos-config"
              "/nix/store/*"
              "/opt/homebrew/*"
            ];
            includeIf."gitdir:/Users/${user}/ir/**".path = "/Users/${user}/.config/git/config-work";
            include.path = "/Users/${user}/.config/git/config-personal";
          };
        };

        # SSH configuration
        ssh = {
          enable = true;
          includes = [ "/Users/${user}/.ssh/config_external" ];
          matchBlocks."github.com" = {
            identitiesOnly = true;
            identityFile = [ "/Users/${user}/.ssh/id_ed25519" ];
          };
        };
      } // (import ./shell-config.nix { inherit config pkgs lib; }).programs;

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
        { path = "/Applications/Safari.app/"; }
        { path = "/Applications/Google Chrome.app/"; }
        { path = "/System/Applications/Music.app/"; }
        { path = "/System/Applications/Calendar.app/"; }
        { path = "/System/Applications/System Settings.app/"; }
      ];
    };
  };
}
