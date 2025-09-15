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
  
  # Emacs pinning logic moved to separate module for modularity
  emacsPinModule = import ./emacs-pinning.nix { inherit pkgs user inputs hostname; };
  configuredEmacs = emacsPinModule.configuredEmacs;
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
        inputs.catppuccin.homeModules.catppuccin
        # inputs.op-shell-plugins.hmModules.default  # Removed - SSH agent integration sufficient
      ] ++ [ ./nushell ];

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = (pkgs.callPackage ./packages.nix {}) ++ [
          inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.nixd-ls.packages.${pkgs.stdenv.hostPlatform.system}.default
          configuredEmacs
        ] ++ emacsPinModule.pinTools;
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
          # Set Xcode developer directory to release version for GUI applications
          DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
          # Ghostty terminfo location for proper terminal support
          TERMINFO_DIRS = "${config.home.homeDirectory}/.terminfo:/usr/share/terminfo";
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

        bat.enable = true;
        kitty.enable = true;
        starship.enable = true;
        zellij.enable = true;
      };

      # Enable the local nushell module
      local.nushell.enable = true;  # Re-enabled to test if it causes fish config issue

      programs = {
        # 1Password shell plugins removed - SSH agent integration is sufficient
        # SSH-based authentication works for GitHub/GitLab via 1Password SSH agent
        # Manual `op` CLI commands available when direct credential access needed
        # This eliminates the deprecated initExtra warning from upstream shell plugins

        atuin = {
          enable = true;
          daemon.enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
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

        bash.enable = true;

        bat = {
          enable = true;
          config = {
            # Theme will be automatically managed by Catppuccin
            # pager = "less -FR";
            # style = "numbers,changes,header";
          };
        };

        helix.enable = true;

        jujutsu = {
          enable = true;
          settings = {
            ui.editor = "nvim";
            lazyjj.highlight-color = "#8839ef";
            user = {
              email = userConfig.email;
              name = userConfig.name;
            };
          };
        };

        kitty = {
          enable = true;
          settings = {
            # Theme will be automatically managed by Catppuccin
            font = "MonoLisaVariable Nerd Font";
            font_size = 18;
            disable_ligatures = "never";
          };
        };

        mise = {
          enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
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

        # Zellij is configured via files.nix to avoid conflicts with custom KDL config
        # programs.zellij.enable = true; (disabled - using manual config file)
        
        zoxide = {
          enable = true;
          enableBashIntegration = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
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

        # SSH configuration with 1Password SSH agent integration
        ssh = {
          enable = true;
          # Disable default config to avoid deprecation warning
          enableDefaultConfig = false;
          includes = [ "/Users/${user}/.ssh/config_external" ];
          
          # Configure 1Password SSH agent for biometric authentication
          extraConfig = ''
            # 1Password SSH Agent Configuration
            Host *
                IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
                StrictHostKeyChecking ask
                IdentitiesOnly no
                ServerAliveInterval 60
                ServerAliveCountMax 3
                Compression no
                UserKnownHostsFile ~/.ssh/known_hosts
          '';
          
          matchBlocks = {
            "github.com" = {
              identitiesOnly = true;
              identityFile = [ "/Users/${user}/.ssh/id_ed25519" ];
            };
            
            # Personal GitLab (use specific host alias to avoid conflicts)
            "gitlab.com-personal" = {
              hostname = "gitlab.com";
              user = "git";
              identitiesOnly = true;
              identityFile = [ "/Users/${user}/.ssh/id_ed25519" ];
            };
            
            # Work GitLab (default gitlab.com - uses work key)
            "gitlab.com" = {
              hostname = "gitlab.com";
              user = "git";
              identitiesOnly = true;
              identityFile = [ "/Users/${user}/.ssh/id_ed25519_gitlab_work" ];
            };
            
            # Alternative work GitLab host (explicit work context)
            "gitlab-work" = {
              hostname = "gitlab.com";
              user = "git";
              identitiesOnly = true;
              identityFile = [ "/Users/${user}/.ssh/id_ed25519_gitlab_work" ];
            };
            
            # Minimal global matchBlock required by home-manager when using extraConfig
            "*" = {
              # Keep this minimal to avoid API issues
            };
          };
        };

        # direnv configuration
        direnv = {
          enable = true;
          nix-direnv.enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
        };

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

      # Enable Emacs service with our configured package
      services.emacs = {
        enable = true;
        package = configuredEmacs;
        client = {
          enable = true;
          arguments = [ "-c" ];
        };
        defaultEditor = false;  # Don't set as EDITOR, we use nvim
        startWithUserSession = true;
      };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };
}
