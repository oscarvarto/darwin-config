{ agenix, config, pkgs, user, hostname, hostSettings, defaultShell ? "zsh", /* nixCats, */ ... }:

let 
  # user and hostname are passed from flake.nix
  # hostSettings contains host-specific configuration flags
  # defaultShell specifies which shell to use as default login shell
  
  # Shell path mapping
  shellPaths = {
    zsh = "/run/current-system/sw/bin/zsh";
    nushell = "/Users/${user}/.nix-profile/bin/nu";
  };
  
  # Get the shell path, fallback to zsh if invalid shell specified
  selectedShellPath = shellPaths.${defaultShell} or shellPaths.zsh;
in

{
  imports = [
    ./modules/secrets.nix
    ./modules/secure-credentials.nix
    ./modules/enhanced-secrets.nix
    ./modules/path-config.nix
    ./modules/home-manager.nix
    ./modules/overlays.nix
    ./modules/terminal-support.nix
    agenix.darwinModules.default
  ];

  # Setup user, packages, programs
  nix = {
    settings = {
      trusted-users = [ "@admin" "${user}" ];
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

      # Maximize build performance 
      max-jobs = "auto";        # Use all available CPU cores
      cores = 0;                # Use all available logical cores for each job
      max-substitution-jobs = 16;  # Increase parallel downloads
      
      # Memory optimization - allow large builds with plenty of RAM
      max-silent-time = 3600;   # 1 hour timeout for silent builds (Emacs compilation)
      timeout = 7200;           # 2 hour total timeout for long builds
      
      # Sandbox and build optimizations
      sandbox = true;
      build-cores = 0;          # Use all cores for building (same as cores but explicit)
      
      warn-dirty = true;
      # produces linking issues when updating on macOS
      # https://github.com/NixOS/nix/issues/7273
      auto-optimise-store = false;
      
      # Fix locale issues in nix builds - ensure consistent locale environment
      extra-sandbox-paths = [];
    };
    
    # Set locale variables for nix daemon and builds
    daemonIOLowPriority = true;
    # daemonCPUSchedPolicy is deprecated, using daemonProcessType instead
    # daemonProcessType = "background"; # Alternative option if needed

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 10d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Global nixpkgs configuration to silence evaluation warnings
  nixpkgs.config = {
    allowAliases = false;  # Disable package aliases to prevent warnings
    allowBroken = true;    # Allow broken packages to work around SDK issues
  };
  
  # Global overlay to provide _1password for shell plugins
  nixpkgs.overlays = [
    (final: prev: {
      _1password = prev._1password-cli;
    })
  ];
  
  # Biometric authentication configuration (main setting is below in security.pam.services)
  
  # Environment variables for 1Password integration with multiple vaults
  environment.variables = {
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
  environment.systemPackages = with pkgs; [
    agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ] ++ (import ./modules/packages.nix { inherit pkgs; });

  # Add selected shell and commonly used shells to available shells
  environment.shells = [ selectedShellPath ] ++ 
    (if defaultShell != "zsh" then [ shellPaths.zsh ] else []) ++
    (if defaultShell != "nushell" then [ shellPaths.nushell ] else []);
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
          "/Users/${user}/Library/Application Support/Coursier/bin"
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

  # Touch ID authorization settings for screen sharing compatibility
  # This allows Touch ID to work with Duet Display and similar screen sharing apps
  # IMPORTANT: This setting affects system authorization (sudo, etc.) only
  # Apple Pay uses a separate security framework and should NOT be affected
  # 
  # TO REVERT IF NEEDED:
  # 1. Comment out or remove the "setTouchIdIgnoreArd" launchd agent below
  # 2. Run: nb && ns  
  # 3. Manually run: defaults delete ~/Library/Preferences/com.apple.security.authorization.plist ignoreArd
  # 
  # If you experience ANY issues with Apple Pay or other Touch ID features,
  # immediately revert this setting using the steps above.
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
        autohide = true;
        show-recents = false;
        launchanim = false;
        orientation = "bottom";
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
