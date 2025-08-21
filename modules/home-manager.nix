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
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${user} = { pkgs, config, lib, ... }: {
      imports = [
        ./git-security-scripts.nix
        inputs.catppuccin.homeModules.catppuccin
        inputs.op-shell-plugins.hmModules.default
      ] ++ [ ./nushell ]; # Always include nushell module for starship integration
      # Fish configuration is handled inline in programs.fish below
      # No separate fish module needed

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
        file = sharedFiles;

        # Ensure user shells and GUI apps see Enchant/Aspell settings + work configuration
        sessionVariables = {
          ENCHANT_ORDERING = "en:aspell,es:aspell,*:aspell";
          ASPELL_CONF = "dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell";
          STARSHIP_CONFIG = "${config.home.homeDirectory}/.config/starship.toml";
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

      catppuccin.flavor = "mocha";
      catppuccin.enable = true;

      # Enable the local nushell module
      local.nushell.enable = true;

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
          enableNushellIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
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
          # Disable shell integrations to prevent PATH conflicts - we manage PATH manually
          enableNushellIntegration = false;
          enableZshIntegration = false;
          enableFishIntegration = false;
          # Use nixpkgs mise package instead of flake to avoid SDK issues
          # package = inputs.mise.packages.${pkgs.stdenv.hostPlatform.system}.default;
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

        fish = {
          enable = true;
          shellInit = ''
            # Nix daemon initialization (equivalent to Nushell initialization)
            if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
                set -gx NIX_SSL_CERT_FILE '/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt'
                set -gx NIX_PROFILES '/nix/var/nix/profiles/default ~/.nix-profile'
                set -gx NIX_PATH 'nixpkgs=flake:nixpkgs'
                fish_add_path --prepend '/nix/var/nix/profiles/default/bin'
            end

            # Environment variables (matching nushell env.nu)
            set -gx AWS_REGION "us-east-1"
            set -gx AWS_DEFAULT_REGION "us-east-1"
            set -gx DOTNET_ROOT "/usr/local/share/dotnet"
            set -gx EMACSDIR "~/.emacs.d"
            set -gx DOOMDIR "~/.doom.d"
            set -gx DOOMLOCALDIR "~/.emacs.d/.local"
            set -gx CARGO_HOME "$HOME/.cargo"

            # Enchant/Aspell configuration (matching nushell)
            set -gx ENCHANT_ORDERING 'en:aspell,es:aspell,*:aspell'
            set -gx ASPELL_CONF 'dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell'

            # Use centralized PATH configuration from modules/path-config.nix
            ${pathConfig.fish.pathSetup or "# PATH config not available"}

            # Editor configuration
            set -gx EDITOR "nvim"
          '';

          # Interactive configuration
          interactiveShellInit = ''
            # Vi mode (matching nushell's vi edit mode)
            fish_vi_key_bindings

            # Let Starship handle the prompt - no custom fish_prompt function
            # This allows starship.toml configuration to work properly
            
            # Authoritative PATH override - ensures our configuration takes precedence over all tools
            ${pathConfig.fish.pathOverride or "# PATH override not available"}
          '';

          # Function definitions (matching some nushell functions)
          functions = {
            # Equivalent to nushell's gp function
            gp = ''
              git fetch --all -p
              git pull
              git submodule update --recursive
            '';
            
            # Equivalent to nushell's search alias  
            search = ''
              rg -p --glob '!node_modules/*' $argv
            '';
            
            # Equivalent to nushell's diff alias
            diff = ''
              difft $argv
            '';

            # Nix shortcuts (matching nushell)
            nb = ''
              pushd ~/darwin-config
              nix run .#build
              popd
            '';
            
            ns = ''
              pushd ~/darwin-config
              nix run .#build-switch  
              popd
            '';

            # Terminal and editor shortcuts (matching nushell aliases)
            tg = ''
              $EDITOR ~/.config/ghostty/config
            '';
            
            tgg = ''
              $EDITOR ~/.config/ghostty/overrides.conf
            '';
            
            nnc = ''
              $EDITOR ~/darwin-config/modules/nushell/config.nu
            '';
            
            nne = ''
              $EDITOR ~/darwin-config/modules/nushell/env.nu
            '';

            # Fish config editing (in home-manager.nix)
            ffc = ''
              $EDITOR ~/darwin-config/modules/home-manager.nix
            '';
          };

          # Abbreviations (like aliases but expandable)
          shellAbbrs = {
            # Doom Emacs shortcuts (matching nushell)
            ds = "doom sync --aot --gc -j (nproc)";
            dup = "doom sync -u --aot --gc -j (nproc)";
            sdup = "doom sync -u --aot --gc -j (nproc) --rebuild";
            
            # Emacs shortcuts
            edd = "emacs --daemon=doom";
            pke = "pkill -9 Emacs";
            tt = "emacs -nw";
            
            # Quick navigation
            ll = "ls -la";
            la = "ls -A";
            l = "ls -CF";
            
            # Git shortcuts
            g = "git";
            ga = "git add";
            gc = "git commit";
            gco = "git checkout";
            gs = "git status";
            gd = "git diff";
            gl = "git log";
          };
        };

        # zellij is installed via homebrew and configured manually
        # We use external config file instead of home-manager settings
        
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
      } // (import ./shell-config.nix { inherit config pkgs lib; }).programs;

      # Shell modules are now conditionally imported based on defaultShell

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
        { path = "/Applications/Zen.app/"; }
        { path = "/Applications/Google Chrome.app/"; }
        { path = "/Applications/Microsoft Edge.app/"; }
        { path = "/Applications/Microsoft Teams.app/"; }
        { path = "/Applications/Microsoft Outlook.app/"; }
        { path = "/Applications/Discord.app/"; }
        { path = "/System/Applications/Music.app/"; }
        { path = "/System/Applications/Calendar.app/"; }
        { path = "/System/Applications/System Settings.app/"; }
      ];
    };
  };
}
