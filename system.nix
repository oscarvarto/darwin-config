{ agenix, config, pkgs, user, hostname, hostSettings, /* nixCats, */ ... }:

let 
  # user and hostname are passed from flake.nix
  # hostSettings contains host-specific configuration flags
in

{
  imports = [
    ./modules/secrets.nix
    ./modules/home-manager.nix
    ./modules/overlays.nix
    agenix.darwinModules.default
  ];

  # Setup user, packages, programs
  nix = {
    settings = {
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org"];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      warn-dirty = true;
      # produces linking issues when updating on macOS
      # https://github.com/NixOS/nix/issues/7273
      auto-optimise-store = false;
    };

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
  

  ids.gids.nixbld = 350;

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs; [
    agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ] ++ (import ./modules/packages.nix { inherit pkgs; });

  # Add nushell to available shells  
  environment.shells = [ "/Users/${user}/.nix-profile/bin/nu" ];

  security.pam.services.sudo_local.touchIdAuth = true;

  programs = {
    zsh.enable = true;
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
