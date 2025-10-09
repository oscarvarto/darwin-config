{
  config,
  pkgs,
  lib,
  ...
} @ args: let
  # Access pathConfig from module args if available
  pathConfig = args.pathConfig or null;
in {
  programs.zsh = {
    # Darwin-specific zsh configuration (nix-darwin options)
    shellInit = ''
      # Environment variables
      export DOTNET_ROOT=/usr/local/share/dotnet
      export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
      export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
      export CARGO_HOME="$HOME/.cargo"
      export EMACSDIR="~/.emacs.d"
      export BAT_THEME="ansi"

      # Use centralized PATH configuration from modules/path-config.nix
      ${
        if pathConfig != null
        then pathConfig.zsh.pathSetup
        else "# Centralized PATH config not available"
      }
    '';

    # Add final PATH cleanup in interactive shells to match fish and nushell consistency
    interactiveShellInit = ''
      # Authoritative PATH override - ensures our configuration takes precedence over all tools
      ${
        if pathConfig != null
        then pathConfig.zsh.pathOverride
        else "# Centralized PATH override not available"
      }
    '';
  };
}
