{ config, pkgs, user, hostname, hostSettings, defaultShell ? "zsh", pathConfig ? null, ... } @ inputs:

let
  sharedFiles = import ./files.nix { inherit config pkgs user; };
  inherit (builtins) fromTOML;
  
  # User configuration based on hostSettings  
  userConfig = {
    # Use secure fallback names - actual credentials will be retrieved dynamically
    name = if hostSettings.enablePersonalConfig then user else user;
    email = if hostSettings.enablePersonalConfig then "${user}@users.noreply.github.com" else "${user}@company.com";
    workDir = if hostSettings.workProfile then "work" else "dev";
  };
  
  # Work configuration - extract pattern without '/**' suffix for directory name
  workConfig = hostSettings.workConfig or {};
  workDirName = builtins.replaceStrings ["~/" "/**"] ["" ""] (workConfig.gitWorkDirPattern or "~/work/**");
in
{

  imports = [
    ./dock
    ./brews.nix
    ./window-manager.nix
    ./zsh-darwin.nix
    ./dock-config.nix
  ];

  # User configuration is now handled in system.nix based on defaultShell

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
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs user pathConfig; };
    users.${user} = { pkgs, config, lib, ... }: {
      imports = [
        ./git-security-scripts.nix
        ./home-activation-scripts.nix
        ./fish-config.nix
        inputs.catppuccin.homeModules.catppuccin
        # inputs.op-shell-plugins.hmModules.default
      ] ++ [ ./nushell ];

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = (pkgs.callPackage ./packages.nix {}) ++ [
          # Add neovim-nightly from overlay
          inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim
          # Add nixd nightly from flake input
          inputs.nixd-ls.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
        file = sharedFiles // {
          
          # Automatic theme switcher script
          ".local/bin/catppuccin-theme-switcher" = {
            executable = true;
            source = ./catppuccin-theme-switcher.sh;
          };
          
          # LaunchAgent for automatic theme switching  
          "Library/LaunchAgents/com.user.catppuccin-theme-switcher.plist" = {
            text = builtins.replaceStrings ["__USER__"] [user] (builtins.readFile ./catppuccin-launchagent.plist);
          };
        };

        # Ensure user shells and GUI apps see Enchant/Aspell settings + work configuration
        sessionVariables = {
          ENCHANT_ORDERING = "en:aspell,es:aspell,*:aspell";
          ASPELL_CONF = "dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell";
          STARSHIP_CONFIG = "${config.home.homeDirectory}/.config/starship.toml";
          # Set Xcode developer directory to beta version for GUI applications
          DEVELOPER_DIR = "/Applications/Xcode-beta.app/Contents/Developer";
          # Work configuration environment variables
          WORK_COMPANY_NAME = workConfig.companyName or "CompanyName";
          WORK_GIT_DIR_PATTERN = workConfig.gitWorkDirPattern or "~/work/**";
          WORK_DB_NAME = workConfig.databaseName or "your_db";
          WORK_DB_HOST = workConfig.databaseHost or "localhost";
          WORK_DB_PORT = workConfig.databasePort or "3306";
          WORK_OP_VAULT = workConfig.opVaultName or "Work";
          WORK_OP_ITEM = workConfig.opItemName or "CompanyName";
        };

        stateVersion = "25.05";
      };

      # Test: re-enable font management to see if it still causes issues
      fonts.fontconfig.enable = true;

      # Enable catppuccin with automatic light/dark switching
      catppuccin = {
        enable = true;
        flavor = "latte"; # Default light theme
        accent = "mauve"; # Accent color
        # Enable automatic theme switching for supported programs
        # Programs will automatically use "latte" in light mode and "mocha" in dark mode
        # Disable starship integration to prevent conflicts with our manual config
        starship.enable = false;
        # Disable zellij integration to prevent conflicts with our manual high-contrast theme
        zellij.enable = false;
      };

      # Enable the local nushell module
      local.nushell.enable = true;  # Re-enabled to test if it causes fish config issue

      programs = {
        # Issue: https://github.com/1Password/shell-plugins/issues/544
        # Fix pending for approval: https://github.com/1Password/shell-plugins/pull/545
        # _1password-shell-plugins = {
        #   # enable 1Password shell plugins for bash, zsh, fish
        #   enable = true;
        #   # the specified packages as well as 1Password CLI will be
        #   # automatically installed and configured to use shell plugins
        #   plugins = with pkgs; [ cachix gh glab ];
        # };

        atuin = {
          enable = true;
          daemon.enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          settings = {
            # General settings
            auto_sync = true;
            sync_frequency = "5m";
            sync_address = "https://api.atuin.sh";
            
            # Search settings
            search_mode = "prefix";
            filter_mode = "global";
            style = "compact";
            
            # History settings
            inline_height = 40;
            show_preview = true;
            max_preview_height = 4;
          };
        };


        helix.enable = true;

        jujutsu = {
          enable = true;
          settings = {
            ui.editor = "nvim";
            user = {
              email = userConfig.email;
              name = userConfig.name;
            };
          };
        };

        mise = {
          enable = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          enableNushellIntegration = true;
        };

        starship = {
          enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
          enableFishIntegration = true;
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
          enableFishIntegration = true;
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
          enableFishIntegration = true;
        };

        # Git configuration
        git = {
          enable = true;
          ignores = (import ./git-ignores.nix { inherit config pkgs lib; }).git.ignores;
          userName = userConfig.name;
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
              "/Users/${user}/darwin-config"
              "/nix/store/*"
              "/opt/homebrew/*"
            ];
            includeIf."gitdir:/Users/${user}/${workDirName}/**".path = "/Users/${user}/.config/git/config-work";
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
        # direnv configuration
        direnv = {
          enable = true;
          nix-direnv.enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
        };
        
        # Fish shell configuration is now imported from fish-config.nix module

        # Zsh with enhanced Fish-like features
        zsh = {
          enable = true;
          autosuggestion.enable = true;  # Fish-like autosuggestions
          syntaxHighlighting.enable = true;  # Fish-like syntax highlighting
          historySubstringSearch.enable = true;  # Better history search
          plugins = [
            {
              name = "fzf-tab";
              src = pkgs.fetchFromGitHub {
                owner = "Aloxaf";
                repo = "fzf-tab";
                rev = "v1.1.2";
                sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
              };
            }
          ];
        };
      } // (import ./shell-config.nix { inherit config pkgs lib; }).programs;

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };
}
