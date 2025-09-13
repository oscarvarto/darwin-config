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
  
  # Emacs pinning system with hash management
  pinFile = "/Users/${user}/.cache/emacs-git-pin";
  hashFile = "/Users/${user}/.cache/emacs-git-pin-hash";
  
  isPinned = builtins.pathExists pinFile;
  
  pinnedCommit = if isPinned 
    then builtins.replaceStrings ["\n"] [""] (builtins.readFile pinFile)
    else null;
    
  pinnedHash = if isPinned && builtins.pathExists hashFile
    then builtins.replaceStrings ["\n"] [""] (builtins.readFile hashFile)
    else null;
    
  # Create emacs package - pinned or latest
  emacsPackage = if isPinned && pinnedCommit != null && pinnedHash != null
    then 
      # Use pinned version with stored hash
      (inputs.emacs-overlay.packages.${pkgs.stdenv.hostPlatform.system}.emacs-git.overrideAttrs (oldAttrs: {
        version = "31.0.50-${builtins.substring 0 7 pinnedCommit}";
        src = pkgs.fetchFromGitHub {
          owner = "emacs-mirror";
          repo = "emacs";
          rev = pinnedCommit;
          sha256 = pinnedHash;
        };
      }))
    else 
      # Use latest version from overlay (when not pinned or hash missing)
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
        # inputs.op-shell-plugins.hmModules.default  # Removed - SSH agent integration sufficient
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
            HASH_FILE="''${CACHE_DIR}/emacs-git-pin-hash"
            
            # Create cache directory if it doesn't exist
            mkdir -p "''${CACHE_DIR}"
            
            if [[ -z "''${COMMIT}" ]]; then
              echo $'\U274C Please specify a commit hash: emacs-pin <commit-hash>'
              echo "   You can find commits at: https://github.com/emacs-mirror/emacs/commits/master"
              echo "   Example: emacs-pin abc123def456"
              exit 1
            fi
            
            # Validate commit hash format (basic check)
            if [[ ! "''${COMMIT}" =~ ^[a-f0-9]{7,40}$ ]]; then
              echo $'\U274C Invalid commit hash format: '"''${COMMIT}"
              exit 1
            fi
            
            echo $'\U1F50D Fetching hash for commit '"''${COMMIT}"$'...'
            
            # Use system-installed nix-prefetch-github
            HASH_RESULT=$(nix-prefetch-github emacs-mirror emacs --rev "''${COMMIT}" 2>/dev/null)
            HASH=$(echo "''${HASH_RESULT}" | grep '"hash"' | sed 's/.*"hash": "\([^"]*\)".*/\1/')
            
            if [[ -z "''${HASH}" || "''${HASH}" == "null" ]]; then
              echo $'\U274C Failed to fetch hash for commit '"''${COMMIT}"
              echo "   Please check that the commit exists in the emacs-mirror/emacs repository."
              exit 1
            fi
            
            # Save the commit hash and its corresponding SHA256
            echo "''${COMMIT}" > "''${PIN_FILE}"
            echo "''${HASH}" > "''${HASH_FILE}"
            
            echo $'\U1F4CC Pinned emacs-git to commit: '"''${COMMIT}"
            echo $'\U1F511 Stored hash: '"''${HASH}"
            echo $'\U1F4A1 Rebuild your configuration: nb && ns'
          '')
          
          (pkgs.writeScriptBin "emacs-unpin" ''
            #!/usr/bin/env bash
            # Unpin emacs-git to use latest commit
            
            set -euo pipefail
            
            CACHE_DIR="''${HOME}/.cache"
            PIN_FILE="''${CACHE_DIR}/emacs-git-pin"
            HASH_FILE="''${CACHE_DIR}/emacs-git-pin-hash"
            
            if [[ -f "''${PIN_FILE}" ]]; then
              PINNED_COMMIT=$(cat "''${PIN_FILE}")
              rm "''${PIN_FILE}"
              [[ -f "''${HASH_FILE}" ]] && rm "''${HASH_FILE}"
              echo $'\U1F513 Unpinned emacs-git from commit: '"''${PINNED_COMMIT}"
              echo $'\U1F4A1 Rebuild your configuration: nb && ns'
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
            HASH_FILE="''${CACHE_DIR}/emacs-git-pin-hash"
            
            if [[ -f "''${PIN_FILE}" ]]; then
              PINNED_COMMIT=$(cat "''${PIN_FILE}")
              echo $'\U1F4CC emacs-git is pinned to commit: '"''${PINNED_COMMIT}"
              echo $'\U1F517 View commit: https://github.com/emacs-mirror/emacs/commit/'"''${PINNED_COMMIT}"
              
              if [[ -f "''${HASH_FILE}" ]]; then
                STORED_HASH=$(cat "''${HASH_FILE}")
                echo $'\U1F511 Stored hash: '"''${STORED_HASH}"
              else
                echo $'\U26A0\UFE0F Warning: No hash file found - pinning may not work correctly'
                echo "   Run: emacs-pin ''${PINNED_COMMIT} to fix"
              fi
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

        # Enable starship integration for automatic color palette management
        starship.enable = true;
        # Enable bat integration for automatic syntax highlighting themes
        bat.enable = true;
        # Enable zellij integration for automatic theming
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

        # Zellij is configured via files.nix to avoid conflicts with custom KDL config
        # programs.zellij.enable = true; (disabled - using manual config file)
        
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
