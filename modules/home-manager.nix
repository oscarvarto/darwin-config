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
  
  # Emacs pinning system
  pinFile = "/Users/oscarvarto/.cache/emacs-git-pin";
  isPinned = builtins.pathExists pinFile;
  pinnedCommit = if isPinned 
    then builtins.readFile pinFile
    else null;
    
  # Create emacs package - pinned or latest
  emacsPackage = if isPinned && pinnedCommit != null
    then 
      # Use pinned version
      (inputs.emacs-overlay.packages.${pkgs.stdenv.hostPlatform.system}.emacs-git.overrideAttrs (oldAttrs: {
        version = "31.0.50-${builtins.substring 0 7 pinnedCommit}";
        src = pkgs.fetchFromGitHub {
          owner = "emacs-mirror";
          repo = "emacs";
          rev = pinnedCommit;
          # This will need to be updated when first pinning - the build will fail with the correct hash
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
        };
      }))
    else 
      # Use latest version from overlay
      inputs.emacs-overlay.packages.${pkgs.stdenv.hostPlatform.system}.emacs-git;
      
  # Apply emacs configuration overrides
  configuredEmacs = emacsPackage.override {
    withNativeCompilation = true;
    withImageMagick = true;
    withWebP = true;
    withTreeSitter = true;
    withSQLite3 = true;
    withMailutils = true;
    # gnutls, librsvg, libxml2, little-cms2, and dynamic modules
    # are enabled by default in recent builds
  };
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
        # ./fish-config.nix  # Commented out to reduce build overhead - using nushell/zsh
        inputs.catppuccin.homeModules.catppuccin
        inputs.op-shell-plugins.hmModules.default
      ] ++ [ ./nushell ];

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = (pkgs.callPackage ./packages.nix {}) ++ [
          inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.nixd-ls.packages.${pkgs.stdenv.hostPlatform.system}.default
          configuredEmacs
          # Emacs pinning CLI tools
          (pkgs.writeScriptBin "emacs-pin" ''
            #!/usr/bin/env bash
            # Pin emacs-git to current or specified commit
            
            set -euo pipefail
            
            COMMIT="''${1:-}"
            CACHE_DIR="''${HOME}/.cache"
            PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
            
            # Create cache directory if it doesn't exist
            mkdir -p "''${CACHE_DIR}"
            
            if [[ -z "''${COMMIT}" ]]; then
              # Get the current commit from emacs-overlay
              echo $'\U1F50D Fetching current emacs-git commit...'
              # This is a simplified version - in practice you might want to query the overlay
              echo $'\U274C Please specify a commit hash: emacs-pin <commit-hash>'
              echo "   You can find commits at: https://github.com/emacs-mirror/emacs/commits/master"
              exit 1
            fi
            
            # Validate commit hash format (basic check)
            if [[ ! "''${COMMIT}" =~ ^[a-f0-9]{7,40}$ ]]; then
              echo $'\U274C Invalid commit hash format: '"''${COMMIT}"
              exit 1
            fi
            
            # Save the commit hash
            echo "''${COMMIT}" > "''${PIN_FILE}"
            echo $'\U1F4CC Pinned emacs-git to commit: '"''${COMMIT}"
            echo $'\U1F4A1 You need to rebuild your configuration: nb && ns'
            echo "   Note: The first build might fail with a hash mismatch."
            echo "   If it does, copy the correct hash from the error and update the configuration."
          '')
          
          (pkgs.writeScriptBin "emacs-unpin" ''
            #!/usr/bin/env bash
            # Unpin emacs-git to use latest commit
            
            set -euo pipefail
            
            CACHE_DIR="''${HOME}/.cache"
            PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
            
            if [[ -f "''${PIN_FILE}" ]]; then
              PINNED_COMMIT=$(cat "''${PIN_FILE}")
              rm "''${PIN_FILE}"
              echo $'\U1F513 Unpinned emacs-git from commit: '"''${PINNED_COMMIT}"
              echo $'\U1F4A1 You need to rebuild your configuration: nb && ns'
              echo "   This will use the latest emacs-git commit from the overlay."
            else
              echo $'\U2139\UFE0F emacs-git is not currently pinned'
            fi
          '')
          
          (pkgs.writeScriptBin "emacs-pin-status" ''
            #!/usr/bin/env bash
            # Show current emacs-git pinning status
            
            set -euo pipefail
            
            CACHE_DIR="''${HOME}/.cache"
            PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
            
            if [[ -f "''${PIN_FILE}" ]]; then
              PINNED_COMMIT=$(cat "''${PIN_FILE}")
              echo $'\U1F4CC emacs-git is pinned to commit: '"''${PINNED_COMMIT}"
              echo $'\U1F517 View commit: https://github.com/emacs-mirror/emacs/commit/'"''${PINNED_COMMIT}"
            else
              echo $'\U1F513 emacs-git is not pinned (using latest from overlay)'
            fi
            
            # Show current emacs version if available
            if command -v emacs >/dev/null 2>&1; then
              echo ""
              echo "Current emacs version:"
              emacs --version | head -1
            fi
          '')
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
          # Set Xcode developer directory to release version for GUI applications
          DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
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
        _1password-shell-plugins = {
          # enable 1Password shell plugins for bash, zsh, fish
          enable = true;
          # the specified packages as well as 1Password CLI will be
          # automatically installed and configured to use shell plugins
          plugins = with pkgs; [ cachix gh glab ];
        };

        atuin = {
          enable = true;
          daemon.enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = false;  # Disabled for faster builds - using nushell/zsh
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
            lazyjj.highlight-color = "#8839ef";
            user = {
              email = userConfig.email;
              name = userConfig.name;
            };
          };
        };

        mise = {
          enable = true;
          enableZshIntegration = true;
          enableFishIntegration = false;  # Disabled for faster builds - using nushell/zsh
          enableNushellIntegration = true;
        };

        starship = {
          enable = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
          enableFishIntegration = false;  # Disabled for faster builds - using nushell/zsh
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
          enableFishIntegration = false;  # Disabled for faster builds - using nushell/zsh
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
          enableFishIntegration = false;  # Disabled for faster builds - using nushell/zsh
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
          includes = [ "/Users/${user}/.ssh/config_external" ];
          
          # Configure 1Password SSH agent for biometric authentication
          extraConfig = ''
            # 1Password SSH Agent Configuration
            Host *
                IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
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
            
            # Global settings for all hosts
            "*" = {
              # These settings optimize 1Password SSH agent usage
              serverAliveInterval = 60;
              serverAliveCountMax = 3;
              # Keep connection alive and prevent hanging
              compression = false;
              hashKnownHosts = false;
              userKnownHostsFile = "/Users/${user}/.ssh/known_hosts";
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
