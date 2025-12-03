{
  description = "macOS Configuration with nix-darwin and home-manager";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    agenix.url = "github:ryantm/agenix";
    catppuccin.url = "github:catppuccin/nix";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bash-env-json = {
      url = "github:tesujimath/bash-env-json";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bash-env-nushell = {
      url = "github:tesujimath/bash-env-nushell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.bash-env-json.follows = "bash-env-json";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-brew = {
      url = "github:Homebrew/brew";
      flake = false;
    };
    homebrew-borkdude = {
      url = "github:borkdude/homebrew-brew";
      flake = false;
    };
    homebrew-jank = {
      url = "github:oscarvarto/homebrew-jank";
      flake = false;
    };
    homebrew-minio = {
      url = "github:minio/homebrew-stable";
      flake = false;
    };
    # jank-lang currently has Darwin build issues (gcc.libc.dev missing)
    # See: https://github.com/jank-lang/jank/blob/main/llvm.nix#L69
    # TODO: Re-enable when upstream fixes Darwin support
    # jank-lang.url = "git+https://github.com/jank-lang/jank.git";
    homebrew-utils = {
      url = "github:JetBrains/homebrew-utils";
      flake = false;
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.brew-src.follows = "homebrew-brew";
    };
    nixd-ls = {
      url = "github:nix-community/nixd";
      flake = true;
    };
    secrets = {
      url = "git+ssh://git@github.com/oscarvarto/nix-secrets.git";
      flake = false;
    };
    # Official emacs-overlay with Apple SDK C23 patch applied locally
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
    };
    crane.url = "github:ipetkov/crane";
  };
  outputs = {
    self,
    nixpkgs,
    flake-parts,
    agenix,
    bash-env-json,
    bash-env-nushell,
    catppuccin,
    darwin,
    home-manager,
    homebrew-bundle,
    homebrew-cask,
    homebrew-core,
    homebrew-brew,
    homebrew-borkdude,
    homebrew-jank,
    # jank-lang, # Disabled due to Darwin build issues
    homebrew-minio,
    homebrew-utils,
    neovim-nightly-overlay,
    nix-homebrew,
    nixd-ls,
    secrets,
    emacs-overlay,
    pyproject-nix,
    pyproject-build-systems,
    uv2nix,
    crane,
  } @ inputs: let
    # Supported systems (Apple Silicon only)
    darwinSystems = ["aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs darwinSystems;

    # Default user configuration - can be overridden per hostname
    defaultUser = "oscarvarto";

    # Host configurations - add new hosts here
    hostConfigs = {
      predator = {
        user = "oscarvarto";
        system = "aarch64-darwin";
        defaultShell = "zsh"; # Options: "zsh", "nushell", "xonsh"
        # Add host-specific settings here
        hostSettings = {
          enablePersonalConfig = true;
          workProfile = false;
          # Work-specific configuration
          workConfig = {
            companyName = "YourCompany"; # Replace with actual company name
            gitWorkDirPattern = "~/work/**"; # Pattern for work git directories
            databaseName = "your_db"; # Work database name
            databaseHost = "localhost";
            databasePort = "3306";
            opVaultName = "Work"; # 1Password vault for work credentials
            opItemName = "CompanyName"; # 1Password item name for work credentials
          };
        };
      };
    };

    recordedConfigPath =
      if builtins.pathExists ./darwin-config-path.nix
      then import ./darwin-config-path.nix
      else null;

    devShell = system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = with pkgs;
        mkShell {
          nativeBuildInputs = with pkgs; [bashInteractive git];
          shellHook = with pkgs; ''
            export EDITOR=nvim
            export VISUAL="zed -w"
          '';
        };
    };

    mkApp = scriptName: system: {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
        #!/usr/bin/env bash
        PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
        echo "Running ${scriptName} for ${system}"
        exec ${self}/apps/${system}/${scriptName} "$@"
      '')}/bin/${scriptName}";
      meta = {
        description = "${scriptName} app for ${system}";
      };
    };

    mkDarwinApps = system: {
      "apply" = mkApp "apply" system;
      "build" = mkApp "build" system;
      "build-switch" = mkApp "build-switch" system;
      "copy-keys" = mkApp "copy-keys" system;
      "create-keys" = mkApp "create-keys" system;
      "check-keys" = mkApp "check-keys" system;
      "rollback" = mkApp "rollback" system;
      "configure-user" = {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "configure-user" ''
          #!/usr/bin/env bash
          # Run the zsh script - compatible with any macOS system
          exec ${self}/scripts/configure-user.sh "$@"
        '')}/bin/configure-user";
        meta = {description = "configure-user app for ${system}";};
      };
      "add-host" = {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "add-host" ''
          #!/usr/bin/env bash
          # Run the zsh script - compatible with any macOS system
          exec ${self}/scripts/add-host.sh "$@"
        '')}/bin/add-host";
        meta = {description = "add-host app for ${system}";};
      };
      "setup-1password-secrets" = {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "setup-1password-secrets" ''
          #!/usr/bin/env bash
          # Set up 1Password for secure git credentials
          exec ${self}/scripts/setup-1password-secrets.sh "$@"
        '')}/bin/setup-1password-secrets";
        meta = {description = "setup-1password-secrets app for ${system}";};
      };
      "setup-pass-secrets" = {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "setup-pass-secrets" ''
          #!/usr/bin/env bash
          # Set up pass for secure git credentials
          exec ${self}/scripts/setup-pass-secrets.sh "$@"
        '')}/bin/setup-pass-secrets";
        meta = {description = "setup-pass-secrets app for ${system}";};
      };
      "sanitize-repo" = {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "sanitize-repo" ''
          #!/usr/bin/env bash
          # Sanitize repository of sensitive information
          exec ${self}/scripts/sanitize-sensitive-data.sh "$@"
        '')}/bin/sanitize-repo";
        meta = {description = "sanitize-repo app for ${system}";};
      };
      "record-config-path" = {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "record-config-path" ''
          #!/usr/bin/env bash
          # Persist the working copy path so scripts can reuse it
          exec ${self}/scripts/record-darwin-config-path.sh "$@"
        '')}/bin/record-config-path";
        meta = {description = "record-config-path app for ${system}";};
      };
      "optimize-nix-performance" = {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "optimize-nix-performance" ''
          #!/usr/bin/env bash
          # Optimize Nix build performance based on hardware specs
          exec ${self}/scripts/optimize-nix-performance.sh "$@"
        '')}/bin/optimize-nix-performance";
        meta = {description = "optimize-nix-performance app for ${system}";};
      };
    };

    mkEmacsPinRust = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      craneLib = crane.mkLib pkgs;

      # Source for the Rust implementation
      # Use path directly since these files are part of the repo
      src = ./modules/emacs-pinning/rust;

      # Common build arguments
      commonArgs = {
        inherit src;
        strictDeps = true;

        buildInputs = [
          pkgs.libiconv
        ];

        # Only build for aarch64-apple-darwin to avoid cross-compilation dependencies
        CARGO_BUILD_TARGET = "aarch64-apple-darwin";
      };

      # Build dependencies (cached separately for faster iteration)
      cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    in
      # Build the actual package
      craneLib.buildPackage (commonArgs
        // {
          inherit cargoArtifacts;
          doCheck = false; # Skip tests in build to speed up compilation
        });

    # Helper function to create darwin configurations with host-specific settings
    mkDarwinConfig = hostname: hostConfig: let
      darwinConfigPath =
        if hostConfig ? configPath
        then hostConfig.configPath
        else if recordedConfigPath != null
        then recordedConfigPath
        else "/Users/${hostConfig.user}/darwin-config";
    in
      darwin.lib.darwinSystem {
        system = hostConfig.system;
        specialArgs =
          inputs
          // {
            inherit (hostConfig) user;
            inherit hostname;
            hostSettings = hostConfig.hostSettings;
            defaultShell = hostConfig.defaultShell or "zsh"; # Default to zsh if not specified
            inherit darwinConfigPath;
            pythonWorkspace = builtins.path {
              path = ./python-env;
              name = "darwin-config-python-env";
            };
            emacsPinRust = mkEmacsPinRust hostConfig.system;
          };
        modules = [
          home-manager.darwinModules.home-manager
          # nix-homebrew disabled - using native Homebrew instead to avoid SDK conflicts
          # nix-homebrew.darwinModules.nix-homebrew
          # {
          #   nix-homebrew = {
          #     user = hostConfig.user;
          #     enable = true;
          #     taps = {
          #       "homebrew/homebrew-core" = homebrew-core;
          #       "homebrew/homebrew-cask" = homebrew-cask;
          #       "homebrew/homebrew-bundle" = homebrew-bundle;
          #       "minio/stable" = homebrew-minio;
          #       "jetbrains/utils" = homebrew-utils;
          #       "borkdude/homebrew-brew" = homebrew-borkdude;
          #       "oscarvarto/homebrew-jank" = homebrew-jank;
          #     };
          #     mutableTaps = true;
          #     autoMigrate = true;
          #   };
          # }
          ./system.nix
        ];
      };
  in {
    devShells = forAllSystems devShell;
    apps = nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

    # Default formatter for `nix fmt .` (Alejandra)
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    darwinConfigurations = nixpkgs.lib.mapAttrs mkDarwinConfig hostConfigs;

    # Expose configuredEmacs and pinTools for each host so scripts can reference them
    packages = nixpkgs.lib.genAttrs darwinSystems (
      system:
        nixpkgs.lib.mapAttrs' (
          hostname: hostConfig: let
            emacsPinModule = import ./modules/emacs-pinning {
              pkgs = nixpkgs.legacyPackages.${system};
              user = hostConfig.user;
              inputs = inputs;
              inherit hostname;
              darwinConfigPath =
                if hostConfig ? configPath
                then hostConfig.configPath
                else if recordedConfigPath != null
                then recordedConfigPath
                else "/Users/${hostConfig.user}/darwin-config";
              # Pass the prebuilt Rust package
              emacsPinRust = mkEmacsPinRust system;
            };
          in
            nixpkgs.lib.nameValuePair "${hostname}-configuredEmacs" emacsPinModule.configuredEmacs
        )
        hostConfigs
        # Add pinTools to the package set
        // nixpkgs.lib.listToAttrs (
          map (tool: {
            name = tool.name;
            value = tool;
          }) (
            let
              # Use first host config to get the pinTools
              firstHostname = builtins.head (builtins.attrNames hostConfigs);
              firstHostConfig = hostConfigs.${firstHostname};
              emacsPinModule = import ./modules/emacs-pinning {
                pkgs = nixpkgs.legacyPackages.${system};
                user = firstHostConfig.user;
                inputs = inputs;
                hostname = firstHostname;
                darwinConfigPath =
                  if firstHostConfig ? configPath
                  then firstHostConfig.configPath
                  else if recordedConfigPath != null
                  then recordedConfigPath
                  else "/Users/${firstHostConfig.user}/darwin-config";
                # Pass the prebuilt Rust package
                emacsPinRust = mkEmacsPinRust system;
              };
            in
              emacsPinModule.pinTools
          )
        )
        # Add the Rust emacs-pin binary itself
        // {
          emacs-pin-rs = mkEmacsPinRust system;
        }
    );
  };
}
