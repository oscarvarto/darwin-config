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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        bash-env-json.follows = "bash-env-json";
      };
    };
    helix = {
      url = "github:gj1118/helix";
      # Use the fork's own pinned nixpkgs/MSRV policy.
    };
    tree-sitter-xonsh = {
      url = "github:oscarvarto/tree-sitter-xonsh";
      flake = false;
    };
    zellij-nix = {
      url = "github:oscarvarto/zellij-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # jank-lang currently has Darwin build issues (gcc.libc.dev missing)
    # See: https://github.com/jank-lang/jank/blob/main/llvm.nix#L69
    # TODO: Re-enable when upstream fixes Darwin support
    # jank-lang.url = "github:jank-lang/jank";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      # Don't follow nixpkgs - overlay needs its own tested version
      # See: nixpkgs removed 'lua' override from neovim-unwrapped
    };
    nixd-ls = {
      url = "github:nix-community/nixd";
      flake = true;
    };
    secrets = {
      url = "git+ssh://git@github.com/oscarvarto/nix-secrets.git";
      flake = false;
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
    helix,
    tree-sitter-xonsh,
    zellij-nix,
    neovim-nightly-overlay,
    nixd-ls,
    secrets,
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
        defaultShell = "zsh"; # Options: "zsh", "nushell", "fish", "xonsh"
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
          shellHook = ''
            export EDITOR=nvim
            export VISUAL="zed --wait"
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
      "build" = mkApp "build" system;
      "build-switch" = mkApp "build-switch" system;
      "copy-keys" = mkApp "copy-keys" system;
      "create-keys" = mkApp "create-keys" system;
      "check-keys" = mkApp "check-keys" system;
      "rollback" = mkApp "rollback" system;
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
    };

    zellijNightlyPackageFor = pkgs: let
      pkgSet = inputs.zellij-nix.packages.${pkgs.stdenv.hostPlatform.system};
      basePkg =
        if pkgSet ? zellij-nightly
        then pkgSet.zellij-nightly
        else pkgSet.default;
    in
      basePkg.overrideAttrs (oldAttrs: {
        buildInputs = (oldAttrs.buildInputs or []) ++ [pkgs.zlib pkgs.curl];
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
            zellijNightlyPackage = zellijNightlyPackageFor;
          };
        modules = [
          home-manager.darwinModules.home-manager
          ./system.nix
        ];
      };
  in {
    devShells = forAllSystems devShell;
    apps = nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      glow = pkgs.glow;
      helix = inputs.helix.packages.${system}.default;
      yazi = pkgs.yazi;
      zellij-nightly = zellijNightlyPackageFor pkgs;
    });

    # Default formatter for `nix fmt .` (Alejandra)
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    darwinConfigurations = nixpkgs.lib.mapAttrs mkDarwinConfig hostConfigs;
  };
}
