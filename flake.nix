{
  description = "macOS Configuration with nix-darwin and home-manager";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
    homebrew-emacs-plus = {
      url = "github:d12frosted/homebrew-emacs-plus";
      flake = false;
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    nixd-ls = {
      url = "github:nix-community/nixd";
      flake = true;
    };
    op-shell-plugins = {
      url = "github:1Password/shell-plugins";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/oscarvarto/nix-secrets.git";
      flake = false;
    };
    # mise = {  # Not needed - using nixpkgs version to avoid SDK issues
    #   url = "github:jdx/mise";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };
  outputs = { self,
              nixpkgs,
              agenix,
              bash-env-json,
              bash-env-nushell,
              catppuccin,
              darwin,
              home-manager,
              homebrew-bundle,
              homebrew-cask,
              homebrew-core,
              homebrew-emacs-plus,
              neovim-nightly-overlay,
              nix-homebrew,
              nixd-ls,
              op-shell-plugins,
              secrets,
              # mise  # not needed - using nixpkgs version
              } @inputs:
    let
      # Default user configuration - can be overridden per hostname
      defaultUser = "oscarvarto";
      
      # Host configurations - add new hosts here
      hostConfigs = {
        predator = {
          user = "oscarvarto";
          system = "aarch64-darwin";
          # Add host-specific settings here
          hostSettings = {
            enablePersonalConfig = true;
            workProfile = false;
          };
        };
        # Example of additional host:
        # macbook-pro = {
        #   user = "otheruser";
        #   system = "x86_64-darwin";
        #   hostSettings = {
        #     enablePersonalConfig = false;
        #     workProfile = true;
        #   };
        # };
      };
      
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs darwinSystems f;
      
      devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git ];
          shellHook = with pkgs; ''
            export EDITOR=nvim
          '';
        };
      };
      
      mkApp = scriptName: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          exec ${self}/apps/${system}/${scriptName}
        '')}/bin/${scriptName}";
      };
      
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
      };
      
      # Helper function to create darwin configurations with host-specific settings
      mkDarwinConfig = hostname: hostConfig: darwin.lib.darwinSystem {
        system = hostConfig.system;
        specialArgs = inputs // { 
          inherit (hostConfig) user;
          inherit hostname;
          hostSettings = hostConfig.hostSettings;
        };
        modules = [
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              user = hostConfig.user;
              enable = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
                "d12frosted/homebrew-emacs-plus" = homebrew-emacs-plus;
              };
              mutableTaps = true;
              autoMigrate = true;
            };
          }
          ./system.nix
        ];
      };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      darwinConfigurations = nixpkgs.lib.mapAttrs mkDarwinConfig hostConfigs;
  };
}
