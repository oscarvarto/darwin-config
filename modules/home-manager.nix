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
  emacsPinRust,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
  pythonWorkspace,
  ...
} @ inputs: let
  sharedFiles = import ./files.nix {inherit config pkgs user;};
  inherit (builtins) fromTOML;

  userHome = lib.attrByPath ["users" "users" user "home"] "/Users/${user}" config;

  # Emacs pinning logic moved to separate module for modularity
  emacsPinModule = import ./emacs-pinning {inherit pkgs user inputs hostname darwinConfigPath emacsPinRust;};
  configuredEmacs = emacsPinModule.configuredEmacs;

  # User configuration based on hostSettings
  userConfig = {
    # Use secure fallback names - actual credentials will be retrieved dynamically
    name =
      if hostSettings.enablePersonalConfig
      then user
      else user;
    email =
      if hostSettings.enablePersonalConfig
      then "${user}@users.noreply.github.com"
      else "${user}@company.com";
    workDir =
      if hostSettings.workProfile
      then "work"
      else "dev";
  };

  # Work configuration - extract pattern without '/**' suffix for directory name
  workConfig = hostSettings.workConfig or {};
  workDirName = builtins.replaceStrings ["~/" "/**"] ["" ""] (workConfig.gitWorkDirPattern or "~/work/**");

  # Wrapper to ensure we only launch the GUI daemon when not already running
  emacsDaemonWrapper = pkgs.writeShellScript "emacs-fg-daemon-wrapper" ''
    #!/usr/bin/env bash
    set -euo pipefail

    EMACSCLIENT="${configuredEmacs}/bin/emacsclient"
    APP="${configuredEmacs}/Applications/Emacs.app"
    DAEMON="${configuredEmacs}/Applications/Emacs.app/Contents/MacOS/Emacs"

    log() {
      printf '[%s] %s\n' "$(date -Iseconds)" "$*" >&2
    }

    # If daemon responds, do nothing (successful exit so launchd doesn't complain)
    if ALTERNATE_EDITOR=false "$EMACSCLIENT" -e "(emacs-version)" >/dev/null 2>&1; then
      exit 0
    fi

    # Launch via LaunchServices so we get the Dock icon when available
    if /usr/bin/open -a "$APP" --args --fg-daemon; then
      exit 0
    fi

    # Fall back to launching the binary directly (e.g. when LaunchServices refuses the bundle)
    log "LaunchServices failed to start Emacs; falling back to direct daemon launch"
    if [[ ! -x "$DAEMON" ]]; then
      log "Emacs binary not found or not executable at $DAEMON"
      exit 1
    fi

    # Start the daemon in the background so launchd can finish quickly
    "$DAEMON" --fg-daemon &
    exit 0
  '';
in {
  imports = [
    ./dock
    ./brews.nix
    ./window-manager.nix
    ./zsh-darwin.nix
    ./dock-config.nix
  ];

  # User configuration is now handled in system.nix based on defaultShell

  environment.variables = {
    # Prevent emacsclient from auto-starting a background daemon; the Emacs
    # daemon is managed by a LaunchAgent that starts the GUI app with --fg-daemon
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
            configuredEmacs
          ]
          ++ emacsPinModule.pinTools;
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

          direnv = {
            enable = true;
            nix-direnv.enable = true;
            enableZshIntegration = true;
            enableNushellIntegration = true;
          };

          # Git configuration
          git = {
            enable = true;
            ignores = (import ./git-ignores.nix {inherit config pkgs lib;}).git.ignores;
            lfs.enable = false;
            settings = {
              user.name = userConfig.name;
              init.defaultBranch = "main";
              core = {
                editor = "emacsclient -t";
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

          mise = {
            enable = true;
            enableZshIntegration = true;
            enableNushellIntegration = true;
          };

          starship = {
            enable = true;
            enableZshIntegration = true;
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

      # Custom Emacs launchd service with proper terminal environment
      launchd.agents.emacs = {
        enable = true;
        config = {
          Label = "org.nix-community.home.emacs";
          # Use wrapper so we don't error when daemon already exists
          ProgramArguments = ["${emacsDaemonWrapper}"];
          # We don't need to keep a helper process alive
          KeepAlive = false;
          RunAtLoad = true;
          # Ensure this runs only in the Aqua (GUI) session and behaves like an interactive app
          LimitLoadToSessionType = "Aqua";
          ProcessType = "Interactive";
          WorkingDirectory = "/Users/${user}";
          EnvironmentVariables = {
            # Set proper terminal environment for emacsclient terminal mode
            SHELL = "/bin/zsh";
            LANG = "en_US.UTF-8";
            LC_ALL = "en_US.UTF-8";
            TERM = "xterm-256color"; # widely compatible terminal type
            COLORTERM = "truecolor";
          };
          StandardErrorPath = "/tmp/emacs-daemon.log";
          StandardOutPath = "/tmp/emacs-daemon.log";
        };
      };

      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };
}
