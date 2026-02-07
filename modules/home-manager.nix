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
  ...
} @ inputs: let
  helixPackage =
    if inputs ? helix
    then inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default
    else pkgs.helix;
  sharedFiles = import ./files.nix {inherit config pkgs user;};

  userHome = lib.attrByPath ["users" "users" user "home"] "/Users/${user}" config;

  # User configuration based on hostSettings
  # Personal identity - used for tools like jujutsu that need build-time values
  userConfig = {
    name = "Oscar Vargas Torres";
    email =
      if hostSettings.enablePersonalConfig
      then "contact@oscarvarto.mx"
      else "work@company.com";
    workDir =
      if hostSettings.workProfile
      then "work"
      else "dev";
  };

  # Work configuration - extract pattern without '/**' suffix for directory name
  workConfig = hostSettings.workConfig or {};
  workDirName = builtins.replaceStrings ["~/" "/**"] ["" ""] (workConfig.gitWorkDirPattern or "~/work/**");

  neovimNightly = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
    EDITOR = "nvim";
    VISUAL = "code-insiders -w";
    GIT_EDITOR = "code-insiders -w";
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
          ./yazelix
          # inputs.op-shell-plugins.hmModules.default  # Removed - SSH agent integration sufficient
        ]
        ++ [./fish-config.nix]
        ++ [./nushell]
        ++ [./xonsh/default.nix];

      xdg = {
        enable = true;
        # Provide a dark Helix theme for Yazelix without changing global flavor.
        configFile."helix/themes/catppuccin-mocha.toml".source = "${config.catppuccin.sources.helix}/${
          if config.catppuccin.helix.useItalics
          then "default"
          else "no_italics"
        }/catppuccin_mocha.toml";
      };

      home = {
        enableNixpkgsReleaseCheck = false;
        packages =
          (import ./packages.nix {inherit pkgs;})
          ++ [
            neovimNightly
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
        # Note: DYLD_LIBRARY_PATH is set per-shell in shell-config.nix, nushell/default.nix,
        # fish-config.nix, and xonsh/default.nix to fix macOS libcrypto "poisoning"
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

        stateVersion = "26.05";
      };

      # Test: re-enable font management to see if it still causes issues
      fonts.fontconfig.enable = true;

      # Enable Catppuccin theming for supported programs
      catppuccin = {
        enable = true;
        flavor = "mocha"; # Default dark theme
        accent = "mauve"; # Accent color
        helix.useItalics = true;

        # starship configuration moved to programs.starship section below
        zellij.enable = true;
      };

      local = {
        # Enable the local fish module
        fish.enable = true;

        # Enable the local nushell module
        nushell.enable = true; # Re-enabled to test if it causes fish config issue

        # Enable the local xonsh module (disabled by default)
        # Xonsh shell configuration
        # Binary: pixi environment (~/darwin-config/python-env/.pixi/envs/default/bin/xonsh)
        # Config: Nix-managed (~/.xonshrc)
        # Packages: pixi-managed (xonsh + xontribs)
        xonsh = {
          enable = true;
          extraConfig = ''
            # =============================================================================
            # Pixi Environment Helper
            # =============================================================================
            from pathlib import Path

            PIXI_ENV_PATH = Path.home() / "darwin-config" / "python-env"

            def _pixi_gt(args):
                """Run pixi commands for the graph-tool environment"""
                if args:
                    cmd = args[0]
                    rest = args[1:] if len(args) > 1 else []
                    ![pixi @(cmd) --manifest-path @(str(PIXI_ENV_PATH / "pixi.toml")) @(rest)]
                else:
                    print("Usage: pixi-gt <command> [args...]")
                    print("Example: pixi-gt shell, pixi-gt run python, pixi-gt add <pkg>")

            aliases['pixi-gt'] = _pixi_gt
          '';
        };
      };

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
          "*.{kt,kts}" = {
            ktlint_code_style = "ktlint_official";
            indent_style = "space";
            indent_size = 4;
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
                editor = "code-insiders -w";
                autocrlf = false;
                eol = "lf";
                ignorecase = false;
                hooksPath = "/Users/${user}/.config/git/hooks";
              };
              # Use SSH for pushes but HTTPS for fetches/clones
              # This keeps compatibility with tools like Zed that expect HTTPS URLs
              url."git@github.com:".pushInsteadOf = "https://github.com/";
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

          helix = {
            enable = true;
            package = helixPackage;
            settings = {
              editor = {
                color-modes = true;
                cursor-shape = {
                  normal = "block";
                  insert = "bar";
                  select = "underline";
                };
                indent-guides.render = true;
                rainbow-brackets = true;
                text-width = 120;
                true-color = true;
              };
              keys = {
                normal = {
                  ";" = "command_mode";
                  ":" = "collapse_selection";

                  # Yazelix sidebar integration - reveal current file in Yazi sidebar
                  A-y = ":sh nu ~/.config/yazelix/nushell/scripts/integrations/reveal_in_yazi.nu \"%{buffer_name}\"";

                  # Navigation and movement
                  "{" = "goto_prev_paragraph";
                  "}" = "goto_next_paragraph";
                  g.e = "goto_file_end";
                  ret = ["move_line_down" "goto_first_nonwhitespace"];
                  A-ret = ["move_line_up" "goto_first_nonwhitespace"];

                  # Selection and editing
                  X = "extend_line_up";
                  C-k = [
                    "extend_to_line_bounds"
                    "delete_selection"
                    "move_line_up"
                    "paste_before"
                  ];
                  C-j = ["extend_to_line_bounds" "delete_selection" "paste_after"];

                  # System integration
                  C-y = ":yank-diagnostic";
                  A-r = [":config-reload" ":reload"];

                  # Text formatting
                  "=" = ":reflow"; # Reflow selected text to text-width (120)

                  # Git integration
                  A-g = {
                    b = ":sh git blame -L %{cursor_line},+1 %{buffer_name}";
                    s = ":sh git status --porcelain";
                    l = ":sh git log --oneline -10 %{buffer_name}";
                  };

                  # Execute selections in shells
                  tab = {
                    x = ":sh \${YAZELIX_DEFAULT_SHELL:-$SHELL} -c '%{selection}'";
                    b = ":sh bash -c '%{selection}'";
                    B = ":sh bash -c 'source ~/.bashrc && %{selection}'";
                    n = ":sh nu -c '%{selection}'";
                    N = ":sh nu -c 'source ~/.config/nushell/config.nu; %{selection}'";

                    # File picker toggles
                    h = ":toggle-option file-picker.hidden";
                    i = ":toggle-option file-picker.git-ignore";

                    # Configuration shortcuts
                    l = ":o ~/.config/helix/languages.toml";
                    c = ":config-open";

                    # AI assist (helix-assist on-demand)
                    # a = ":pipe-to helix-assist --handler anthropic --debug-query -";
                  };
                };
              };
            };
            languages = {
              language = [
                {
                  name = "java";
                  scope = "source.java";
                  file-types = ["java"];
                  roots = ["pom.xml" "build.gradle" "build.gradle.kts" ".git"];
                  indent = {
                    tab-width = 4;
                    unit = "    ";
                  };
                  language-servers = ["jdtls" "tabby" "helix-assist"];
                }
                {
                  name = "kotlin";
                  scope = "source.kotlin";
                  file-types = ["kt" "kts"];
                  roots = ["settings.gradle" "settings.gradle.kts" ".git"];
                  comment-token = "//";
                  block-comment-tokens = {
                    start = "/*";
                    end = "*/";
                  };
                  indent = {
                    tab-width = 4;
                    unit = "    ";
                  };
                  language-servers = ["kotlin-lsp" "tabby" "helix-assist"];
                }
                {
                  name = "markdown";
                  language-servers = ["marksman" "harper-ls"];
                }
                {
                  name = "nix";
                  auto-format = true;
                  formatter.command = lib.getExe pkgs.alejandra;
                  language-servers = ["nixd" "tabby" "helix-assist"];
                }
                {
                  name = "ocaml";
                  auto-format = true;
                  formatter = {command = "ocamlformat";};
                  file-types = ["ml" "mli"];
                  # TODO: Refine for other useful settings
                  roots = [".git"];
                  language-servers = ["ocamllsp" "tabby" "helix-assist"];
                }
                {
                  name = "python";
                  file-types = ["py"];
                  auto-format = true;
                  roots = ["pyproject.toml" ".git" ".jj" ".venv/"];
                  comment-token = "#";
                  shebangs = ["python"];
                  language-servers = ["ty" "ruff" "tabby" "helix-assist"];
                }
                {
                  name = "xonsh";
                  scope = "source.xonsh";
                  grammar = "xonsh";
                  file-types = ["xsh" "xonshrc"];
                  roots = ["pyproject.toml" ".git" ".jj" ".venv/"];
                  comment-token = "#";
                  shebangs = ["xonsh"];
                  auto-pairs = {
                    "(" = ")";
                    "[" = "]";
                    "{" = "}";
                    "\"" = "\"";
                    "'" = "'";
                    "`" = "`";
                  };
                  language-servers = ["ty" "ruff" "tabby" "helix-assist"];
                }
                {
                  name = "rust";
                  auto-format = true;
                  formatter = {
                    command = "cargo";
                    args = ["fmt" "--" "--emit=stdout"];
                  };
                  language-servers = ["rust-analyzer" "tabby" "helix-assist"];
                }
                {
                  name = "scala";
                  language-servers = ["metals" "tabby" "helix-assist"];
                }
              ];
              language-server = {
                harper-ls = {
                  command = "harper-ls"; # Installed from source: cargo install --path harper-ls
                  args = ["--stdio"];
                  config.harper-ls.linters = {
                    SpellCheck = false;
                    SentenceCapitalization = false;
                    UseTitleCase = false;
                    SplitWords = false;
                    ExpandMinimum = false;
                    ExpandMemoryShorthands = false;
                    OrthographicConsistency = false;
                    DisjointPrefixes = false;
                    PhrasalVerbAsCompoundNoun = false;
                    NeedToNoun = false;
                    MissingTo = false;
                  };
                };
                jdtls = {
                  command = "jdtls-wrapper";
                  args = ["--jvm-arg=-javaagent:/Users/oscarvarto/.lombok/lombok.jar"];
                  config = {
                    java.inlayHints.parameterNames.enabled = "all";
                    extendedClientCapabilities.classFileContentsSupport = true;
                  };
                };
                kotlin-lsp = {
                  command = "kotlin-lsp";
                  environment = {
                    JAVA_HOME = "${pkgs.jdk25}";
                  };
                };
                markdown-oxide = {command = "markdown-oxide";};
                marksman = {
                  # Use system marksman (install via: brew install marksman)
                  command = "marksman";
                };
                metals = {command = "metals";};
                nixd = {command = "nixd";};
                ocamllsp = {command = "ocamllsp";};
                ruff = {
                  command = "ruff";
                  args = ["server"];
                };
                ty = {
                  command = "ty";
                  args = ["server"];
                };
                helix-assist = {
                  command = "helix-assist";
                  args = [
                    "--handler"
                    "anthropic"
                    "--num-suggestions"
                    "2"
                  ];
                };
                tabby = {
                  command = "npx";
                  args = ["--yes" "tabby-agent" "--stdio"];
                };
              };
            };
          };

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
                identityAgent = "none";
                identityFile = ["/Users/${user}/.ssh/id_ed25519_nix_account"];
                extraOptions = {
                  BatchMode = "yes";
                  StrictHostKeyChecking = "accept-new";
                };
              };

              # GitLab configuration
              "gitlab.com" = {
                hostname = "gitlab.com";
                user = "git";
                identitiesOnly = true;
                identityFile = ["/Users/${user}/.ssh/id_ed25519"];
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
              show_hidden = true;
              mgr = {
                ratio = [1 3 4];
                sort_by = "natural";
              };
            };
          };

          yazelix = {
            enable = true;
            # Dependency control for specific use cases
            recommended_deps = true; # Productivity tools like lazygit, atuin
            yazi_extensions = true; # File preview support
            yazi_media = true; # Enable heavy media processing (~1GB)

            # Multi-shell environment
            default_shell = "nu";
            extra_shells = ["fish" "zsh"]; # Install additional shells

            # Terminal preference
            preferred_terminal = "ghostty"; # Better for media previews
            terminal_config_mode = "yazelix";
            transparency = "none";

            # Editor configuration
            # editor_command = null;       # Default: Use yazelix's Helix (recommended)
            editor_command = "hx";
            # editor_command = "nvim";     # Alternative: Use other editor (loses Helix features)
            helix_theme = "catppuccin-mocha";
            helix_command_key = ";";

            # Development-friendly settings
            debug_mode = true; # Enable verbose logging
            skip_welcome_screen = true; # Show welcome screen
            ascii_art_mode = "animated"; # Static ASCII art for faster startup

            # Persistent sessions for long-running work
            persistent_sessions = false;
            session_name = "main-dev";

            yazi_plugins = [
              "git"
              "piper"
              "starship"
            ];

            # Catppuccin Mocha theme for consistent look
            yazi_theme = "catppuccin-mocha";
            zellij_theme = "catppuccin-mocha";

            # Additional tools for development workflow
            user_packages = with pkgs; [
              # Package management
              cargo-update
              mise

              # Development tools
              ruff # Python linting/formatting
              biome # JS/TS formatting and linting

              # Language servers
              typescript-language-server
              typescript # Required peer dependency

              # File management
              ouch # Archive handling
              erdtree # Modern tree command

              # Markdown preview
              glow
            ];
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
