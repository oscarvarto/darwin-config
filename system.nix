{
  agenix,
  config,
  pkgs,
  user,
  hostname,
  hostSettings,
  defaultShell ? "zsh",
  darwinConfigPath,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
  pythonWorkspace,
  /*
  nixCats,
  */
  ...
}: let
  # user and hostname are passed from flake.nix
  # hostSettings contains host-specific configuration flags
  # defaultShell specifies which shell to use as default login shell
  # Shell path mapping
  shellPaths = {
    bash = "/Users/${user}/.nix-profile/bin/bash";
    zsh = "/Users/${user}/.nix-profile/bin/zsh";
    nushell = "/Users/${user}/.nix-profile/bin/nu";
    xonsh = "/Users/${user}/.nix-profile/bin/xonsh";
  };

  # Get the shell path, fallback to zsh if invalid shell specified
  selectedShellPath = shellPaths.${defaultShell} or shellPaths.zsh;
in {
  imports = [
    ./modules/secrets.nix
    ./modules/secure-credentials.nix
    ./modules/enhanced-secrets.nix
    ./modules/path-config.nix
    ./modules/home-manager.nix
    ./modules/overlays.nix
    agenix.darwinModules.default
  ];

  # Setup user, packages, programs
  nix = {
    settings = {
      trusted-users = ["@admin" "${user}"];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
        # Add emacs-overlay cache for pre-built Emacs binaries
        "https://emacs-ci.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrThNT2ag4G+BWZZbaaDtwM="
      ];

      # Dynamic build performance settings based on hardware specs
      # Hardware-optimized settings applied on Sun Sep 14 13:10:00 CST 2025 for 16 cores, 128GB RAM
      # These settings are auto-detected and configured during setup
      max-jobs = 64; # Hardware-optimized: 16 cores detected
      cores = 0; # Use all available logical cores for each job
      max-substitution-jobs = 64; # Hardware-optimized for network performance

      # Memory optimization - allow large builds with plenty of RAM
      max-silent-time = 3600; # 1 hour timeout for silent builds (Emacs compilation)
      timeout = 7200; # 2 hour total timeout for long builds

      # Advanced build performance settings
      build-cores = 0; # Use all cores for building (same as cores but explicit)

      # Memory and I/O optimizations (will be configured based on available RAM)
      min-free = 6871947673; # Hardware-optimized: 6.3GB minimum
      max-free = 82463372083; # Hardware-optimized: 76.7GB threshold

      # Network optimizations
      connect-timeout = 10; # 10 second connection timeout
      download-attempts = 3; # Retry failed downloads

      # Build environment optimizations
      keep-going = true; # Continue building other derivations on failure
      keep-failed = false; # Don't keep failed build directories (saves space)

      # Experimental features for better performance
      eval-cache = true; # Cache evaluation results
      tarball-ttl = 300; # Cache tarballs for 5 minutes

      warn-dirty = false;
      # produces linking issues when updating on macOS
      # https://github.com/NixOS/nix/issues/7273
      auto-optimise-store = false;

      # Sandbox configuration for better compatibility with Codex CLI and other tools
      # "relaxed" allows fixed-output derivations to run without sandboxing
      # This is particularly helpful for tools like Codex that interact with the broader system
      sandbox = "relaxed";

      # Fix locale issues in nix builds - ensure consistent locale environment
      # These sandbox paths allow access to system locale files
      # Additional paths for Codex CLI and other tools that need broader system access
      extra-sandbox-paths = [
        "/usr/share/locale"
        "/System/Library"
        "/usr/lib"
        "/usr/bin"
        "/bin"
        "/opt/homebrew"
        "/private/tmp"
        "/private/var/tmp"
      ];
    };

    # Daemon performance settings for faster builds
    daemonIOLowPriority = false; # Hardware-optimized: high (plenty of resources)
    # Don't set daemonProcessType to allow normal CPU scheduling priority

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 10d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      # Enhanced build visibility and progress indicators
      log-lines = 100
      show-trace = true
      # print-build-logs = true  # Removed: unknown setting in current Nix version

      # Fix locale issues for Mexico-based systems
      # Force consistent en_US.UTF-8 locale in all build environments
    '';
  };

  # Global nixpkgs configuration to silence evaluation warnings
  nixpkgs.config = {
    allowAliases = false; # Disable package aliases to prevent warnings
    allowBroken = true; # Allow broken packages to work around SDK issues
  };

  # Global overlay to provide _1password for shell plugins
  nixpkgs.overlays = [
    (final: prev: {
      _1password = prev._1password-cli;
    })
    (final: prev: {
      rubyPackages_3_3 = prev.rubyPackages_3_3.overrideScope' (self: super: {
        nokogiri = super.nokogiri.overrideAttrs (old: {
          NIX_CFLAGS_COMPILE =
            (old.NIX_CFLAGS_COMPILE or "")
            + " -Wno-error=unused-command-line-argument"
            + " -Wno-error=default-const-init-field-unsafe";
        });
      });
      assimp = prev.assimp.overrideAttrs (old: {
        NIX_CFLAGS_COMPILE =
          (old.NIX_CFLAGS_COMPILE or "")
          + " -Wno-error=character-conversion";
        cmakeFlags = (old.cmakeFlags or []) ++ ["-DASSIMP_BUILD_TESTS=OFF"];
        doCheck = false;
      });
      bash-preexec = prev.bash-preexec.overrideAttrs (old: {
        doCheck = false;
        checkPhase = "";
        nativeBuildInputs =
          builtins.filter (pkg: pkg != prev.bats) (old.nativeBuildInputs or []);
      });
    })
  ];

  # Biometric authentication configuration (main setting is below in security.pam.services)

  # Environment variables for 1Password integration with multiple vaults
  environment.variables = {
    DARWIN_CONFIG_PATH = darwinConfigPath;
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    OP_VAULT_PERSONAL = "Personal";
    OP_VAULT_WORK = "Work";
    # Fix locale issues in nix builds by setting locale environment variables
    # These variables ensure that all Nix builds use consistent locale settings
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_COLLATE = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  ids.gids.nixbld = 350;

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs;
    [
      agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
    ]
    ++ (
      import ./modules/packages.nix {
        inherit
          pkgs
          uv2nix
          pyproject-nix
          pyproject-build-systems
          pythonWorkspace
          ;
      }
    );

  # Add selected shell and commonly used shells to available shells
  environment.shells =
    [selectedShellPath]
    ++ (
      if defaultShell != "zsh"
      then [shellPaths.zsh]
      else []
    )
    ++ (
      if defaultShell != "nushell"
      then [shellPaths.nushell]
      else []
    );
  # fish shell removed - only kept as nushell multicompleter dependency

  # Configure the selected user with the chosen shell
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = selectedShellPath;
  };

  # Touch ID configuration for macOS 26 (uses pam_tid.so.2)
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    text = ''
      auth       sufficient     pam_tid.so.2
    '';
  };

  programs = {
    zsh.enable = true;
    # fish.enable removed - only kept as nushell multicompleter dependency
  };

  # User-level launchd agent to set environment variables for GUI applications
  # This works with SIP enabled and provides the same functionality as system-level launchd.envVariables
  launchd.user.agents.setEnvVars = {
    serviceConfig = {
      Label = "org.nixos.setEnvVars";
      ProgramArguments = [
        "/bin/launchctl"
        "setenv"
        "PATH"
        (builtins.concatStringsSep ":" [
          # User script directories
          "/Users/${user}/.local/bin"
          "/Users/${user}/.local/share/bin"
          "/Users/${user}/.cargo/bin"
          "/Users/${user}/.emacs.d/bin"
          "/Users/${user}/.volta/bin"
          # Nix paths (essential for Nix-managed tools)
          "/Users/${user}/.nix-profile/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"

          # Homebrew paths
          "/opt/homebrew/bin"
          "/opt/homebrew/opt/llvm/bin"
          "/opt/homebrew/opt/mysql@8.4/bin"
          "/opt/homebrew/opt/gnu-tar/libexec/gnubin"

          # System paths
          "/usr/local/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
          "/Library/Apple/usr/bin"
          "/Library/TeX/texbin"
        ])
      ];
      RunAtLoad = true;
    };
  };

  launchd.user.agents.setDarwinConfigPath = {
    serviceConfig = {
      Label = "org.nixos.setDarwinConfigPath";
      ProgramArguments = [
        "/bin/launchctl"
        "setenv"
        "DARWIN_CONFIG_PATH"
        darwinConfigPath
      ];
      RunAtLoad = true;
    };
  };

  # Additional launchd agents for locale settings to fix "LANG=en_MX.UTF-8 cannot be used" warning
  launchd.user.agents.setLangVar = {
    serviceConfig = {
      Label = "org.nixos.setLangVar";
      ProgramArguments = [
        "/bin/launchctl"
        "setenv"
        "LANG"
        "en_US.UTF-8"
      ];
      RunAtLoad = true;
    };
  };

  # Prevent emacsclient from auto-starting a background daemon for GUI apps
  launchd.user.agents.setAlternateEditorVar = {
    serviceConfig = {
      Label = "org.nixos.setAlternateEditorVar";
      ProgramArguments = [
        "/bin/launchctl"
        "setenv"
        "ALTERNATE_EDITOR"
        "false"
      ];
      RunAtLoad = true;
    };
  };

  launchd.user.agents.setLcAllVar = {
    serviceConfig = {
      Label = "org.nixos.setLcAllVar";
      ProgramArguments = [
        "/bin/launchctl"
        "setenv"
        "LC_ALL"
        "en_US.UTF-8"
      ];
      RunAtLoad = true;
    };
  };

  # Set DEVELOPER_DIR to point to Xcode for GUI applications
  launchd.user.agents.setDeveloperDirVar = {
    serviceConfig = {
      Label = "org.nixos.setDeveloperDirVar";
      ProgramArguments = [
        "/bin/launchctl"
        "setenv"
        "DEVELOPER_DIR"
        "/Applications/Xcode.app/Contents/Developer"
      ];
      RunAtLoad = true;
    };
  };

  # Set MACOSX_DEPLOYMENT_TARGET for gcc-15
  launchd.user.agents.setMacOSXDeploymentTargetVar = {
    serviceConfig = {
      Label = "org.nixos.setMacOSXDeploymentTargetVar";
      ProgramArguments = [
        "/bin/launchctl"
        "setenv"
        "MACOSX_DEPLOYMENT_TARGET"
        "26.0"
      ];
      RunAtLoad = true;
    };
  };

  # Fix locale for Nix builds - override macOS en_MX.UTF-8 with en_US.UTF-8
  # This overrides the system locale for all processes started via launchctl
  launchd.user.agents.overrideLangForNix = {
    serviceConfig = {
      Label = "org.nixos.overrideLangForNix";
      ProgramArguments = [
        "/bin/bash"
        "-c"
        "launchctl setenv LANG en_US.UTF-8 && launchctl setenv LC_ALL en_US.UTF-8"
      ];
      RunAtLoad = true;
    };
  };

  launchd.user.agents.setTouchIdIgnoreArd = {
    serviceConfig = {
      Label = "org.nixos.setTouchIdIgnoreArd";
      ProgramArguments = [
        "/usr/bin/defaults"
        "write"
        "/Users/${user}/Library/Preferences/com.apple.security.authorization.plist"
        "ignoreArd"
        "-bool"
        "true"
      ];
      RunAtLoad = true;
    };
  };

  # Font packages removed to avoid SDK compatibility issues
  # Fonts can be installed via system preferences or homebrew if needed

  system = {
    stateVersion = 4;
    primaryUser = user;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = false;
        show-recents = false;
        launchanim = false;
        orientation = "left";
        tilesize = 50;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = false;
      };
    };
  };
}
