{
  config,
  lib,
  pkgs,
  user,
  hostname,
  hostSettings,
  defaultShell ? "zsh",
  pathConfig ? null,
  darwinConfigPath,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
  pythonWorkspace,
  ...
} @ inputs: let
  sharedFiles = import ./files.nix {inherit config pkgs user;};
  inherit (builtins) fromTOML;

  userHome = lib.attrByPath ["users" "users" user "home"] "/Users/${user}" config;

  # User configuration based on hostSettings
  # Personal identity - used for tools like jujutsu that need build-time values
  userConfig = {
    name = "Oscar Vargas Torres";
    email =
      if hostSettings.enablePersonalConfig
      then "contact@oscarvarto.mx"
      else "oscar.vargas@irhythmtech.com";
    workDir =
      if hostSettings.workProfile
      then "work"
      else "dev";
  };

  # Work configuration - extract pattern without '/**' suffix for directory name
  workConfig = hostSettings.workConfig or {};
  workDirName = builtins.replaceStrings ["~/" "/**"] ["" ""] (workConfig.gitWorkDirPattern or "~/work/**");
in {
  imports = [
    ./dock
    ./window-manager.nix
    ./zsh-darwin.nix
    ./dock-config.nix
  ];

  # User configuration is now handled in system.nix based on defaultShell

  environment.variables = {
    # Prevent emacsclient from auto-starting a background daemon
    # Start Emacs daemon manually with: emacs --daemon
    ALTERNATE_EDITOR = "false";
    EDITOR = "emacsclient -t";
    VISUAL = "zed -w";
    GIT_EDITOR = "emacsclient -t";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    BAT_THEME = "ansi";
    # Force Enchant to use aspell and point aspell to the Nix-provided dictionaries
    ENCHANT_ORDERING = "en:aspell,es:aspell,*:aspell";
    ASPELL_CONF = "dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [en en-computers en-science es])}/lib/aspell";

    # Xonsh configuration - suppress xontrib warnings during startup health checks
    XONSH_SUPPRESS_COMP_WARNINGS = "True";
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs user pathConfig darwinConfigPath;};
    users.${user} = {
      pkgs,
      config,
      lib,
      ...
    }: {
      imports =
        [
          ./git-security-scripts.nix
          ./home-activation-scripts.nix
          inputs.catppuccin.homeModules.catppuccin
          # inputs.op-shell-plugins.hmModules.default  # Removed - SSH agent integration sufficient
        ]
        ++ [./fish-config.nix]
        ++ [./nushell]
        ++ [./xonsh/default.nix];

      home = {
        enableNixpkgsReleaseCheck = false;
        packages =
          (import ./packages.nix {
            inherit pkgs uv2nix pyproject-nix pyproject-build-systems pythonWorkspace;
          })
          ++ [
            inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default
            inputs.nixd-ls.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        file =
          sharedFiles
          // {
            # Catppuccin theme switcher script (manual invocation)
            ".local/bin/catppuccin-theme-switcher" = {
              executable = true;
              source = ./catppuccin-theme-switcher.sh;
            };
          };

        # Ensure user shells and GUI apps see Enchant/Aspell settings + work configuration
        sessionVariables = {
          ENCHANT_ORDERING = "en:aspell,es:aspell,*:aspell";
          ASPELL_CONF = "dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [en en-computers en-science es])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell";
          STARSHIP_CONFIG = "${config.home.homeDirectory}/.config/starship.toml";
          # Xonsh configuration - suppress xontrib warnings during startup health checks
          XONSH_SUPPRESS_COMP_WARNINGS = "True";
          # Set Xcode developer directory to release version for GUI applications
          DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
          # Ghostty terminfo location for proper terminal support
          TERMINFO_DIRS = "${config.home.homeDirectory}/.terminfo:/usr/share/terminfo";
          DARWIN_CONFIG_PATH = darwinConfigPath;
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

      # Enable Catppuccin theming for supported programs
      catppuccin = {
        enable = true;
        flavor = "mocha"; # Default light theme
        accent = "mauve"; # Accent color

        # starship configuration moved to programs.starship section below
        zellij.enable = true;
      };

      # Enable the local fish module
      local.fish.enable = true;

      # Enable the local nushell module
      local.nushell.enable = true; # Re-enabled to test if it causes fish config issue

      # Enable the local xonsh module (disabled by default)
      local.xonsh.enable = true; # Set to true to enable xonsh

      # Global EditorConfig (Home Manager module)
      editorconfig = {
        enable = true;
        settings = {
          "*" = {
            charset = "utf-8";
            end_of_line = "lf";
            insert_final_newline = true;
            trim_trailing_whitespace = false;
            indent_style = "space";
            indent_size = 2;
          };
          "*.md" = {trim_trailing_whitespace = false;};
          Makefile = {indent_style = "tab";};
          "*.go" = {indent_style = "tab";};
          "*.py" = {
            indent_style = "space";
            indent_size = 4;
          };
          "*.nix" = {
            indent_style = "space";
            indent_size = 2;
          };
          "*.lua" = {
            indent_style = "space";
            indent_size = 2;
          };
          "*.nu" = {
            indent_style = "space";
            indent_size = 2;
          };
          "*.{js,jsx,ts,tsx,json,yml,yaml,toml,sh,bash,zsh}" = {
            indent_style = "space";
            indent_size = 2;
          };
        };
      };

      programs =
        {
          # 1Password shell plugins removed - SSH agent integration is sufficient
          # SSH-based authentication works for GitHub/GitLab via 1Password SSH agent
          # Manual `op` CLI commands available when direct credential access needed
          # This eliminates the deprecated initExtra warning from upstream shell plugins

          bash.enable = true;

          direnv = {
            enable = true;
            nix-direnv.enable = true;
            enableBashIntegration = true;
            enableZshIntegration = true;
            # enableFishIntegration = true; # Automatically enabled by fish module
            enableNushellIntegration = true;
          };

          # Git configuration
          git = {
            enable = true;
            ignores = (import ./git-ignores.nix {inherit config pkgs lib;}).git.ignores;
            lfs.enable = false;
            settings = {
              # user.name and user.email handled by conditional includes
              init.defaultBranch = "main";
              core = {
                editor = "emacsclient -t";
                autocrlf = false;
                eol = "lf";
                ignorecase = false;
              };
              # Force SSH instead of HTTPS for GitHub
              url."git@github.com:".insteadOf = "https://github.com/";
              commit.gpgsign = false;
              diff.colorMoved = "zebra";
              fetch.prune = true;
              pull.rebase = true;
              push.autoSetupRemote = true;
              push.default = "current";
              rebase.autoStash = true;
              safe.directory = [
                "*"
                "${darwinConfigPath}"
                "/nix/store/*"
                "/opt/homebrew/*"
              ];
              includeIf."gitdir:/Users/${user}/${workDirName}/**".path = "/Users/${user}/.config/git/config-work";
              include.path = "/Users/${user}/.config/git/config-personal";
            };
          };

          helix.enable = true;

          jujutsu = {
            enable = true;
            settings = {
              ui.editor = "emacsclient -t";
              lazyjj.highlight-color = "#8839ef";
              user = {
                email = userConfig.email;
                name = userConfig.name;
              };
            };
          };

          # Temporarily disable mise integrations to avoid build issues
          # We'll use the existing mise from system profile instead
          mise = {
            enable = true;
            enableBashIntegration = true;
            enableFishIntegration = true;
            enableZshIntegration = true; # Disable to avoid zshrc build issues
            enableNushellIntegration = false; # Disabled - generated config incompatible with current Nushell
          };

          starship = {
            enable = true;
            enableBashIntegration = true;
            enableZshIntegration = true;
            enableFishIntegration = true;
            enableNushellIntegration = true;
            settings =
              fromTOML (builtins.readFile ./starship.toml)
              // {
                # Dynamic palette selection based on catppuccin flavor
                palette =
                  if config.catppuccin.flavor == "mocha"
                  then "catppuccin_mocha"
                  else "catppuccin_latte";
              };
          };

          # SSH configuration with 1Password SSH agent integration
          ssh = {
            enable = true;
            # Disable default config to avoid deprecation warning
            enableDefaultConfig = false;
            includes = ["/Users/${user}/.ssh/config_external"];

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
                identityFile = ["/Users/${user}/.ssh/id_ed25519"];
              };

              # Personal GitLab (use specific host alias to avoid conflicts)
              "gitlab.com-personal" = {
                hostname = "gitlab.com";
                user = "git";
                identitiesOnly = true;
                identityFile = ["/Users/${user}/.ssh/id_ed25519"];
              };

              # Work GitLab (default gitlab.com - uses work key)
              "gitlab.com" = {
                hostname = "gitlab.com";
                user = "git";
                identitiesOnly = true;
                identityFile = ["/Users/${user}/.ssh/id_ed25519_gitlab_work"];
              };

              # Alternative work GitLab host (explicit work context)
              "gitlab-work" = {
                hostname = "gitlab.com";
                user = "git";
                identitiesOnly = true;
                identityFile = ["/Users/${user}/.ssh/id_ed25519_gitlab_work"];
              };

              # Minimal global matchBlock required by home-manager when using extraConfig
              "*" = {
                # Keep this minimal to avoid API issues
              };
            };
          };

          yazi = {
            enable = true;
            enableFishIntegration = true;
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
            enableFishIntegration = true;
            enableNushellIntegration = true;
            enableZshIntegration = true;
          };

          # Zsh with enhanced Fish-like features
          zsh = {
            enable = true;
            autosuggestion.enable = true; # Fish-like autosuggestions
            syntaxHighlighting.enable = true; # Fish-like syntax highlighting
            historySubstringSearch.enable = true; # Better history search
            # Ensure final PATH override runs at end of ~/.zshrc so it wins
            initExtra = lib.mkAfter ''
              # Centralized PATH final override (post-plugins)
              ${
                if pathConfig != null
                then pathConfig.zsh.pathOverride
                else "# Centralized PATH override not available"
              }
            '';
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
        }
        // (import ./shell-config.nix {inherit config pkgs lib pathConfig darwinConfigPath;}).programs;

      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };
}
