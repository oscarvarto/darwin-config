{ config, pkgs, lib, pathConfig ? null, ... }:

{
  programs.fish = {
    enable = true;
    
    # Login shell initialization - minimal setup
    loginShellInit = ''
      # Set ASPELL_CONF with Nix paths (must be set in Nix context)
      set -gx ASPELL_CONF 'dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell'
      
      # Apply centralized PATH configuration if available
      ${if pathConfig != null then pathConfig.fish.pathSetup else ""}
      
      # Source the main login configuration if it exists
      if test -f ~/darwin-config/fish-login-init.fish
        source ~/darwin-config/fish-login-init.fish
      end
    '';

    # Interactive shell initialization - minimal setup
    interactiveShellInit = ''
      # Source the main interactive configuration if it exists
      if test -f ~/darwin-config/fish-interactive-init.fish
        source ~/darwin-config/fish-interactive-init.fish
      end
      
      # Authoritative PATH override - ensures our configuration takes precedence over all tools
      ${if pathConfig != null then pathConfig.fish.pathOverride else ""}
    '';

    # Minimal function definitions - only essentials for fish functionality
    # Most functions are handled by scripts in ~/.local/share/bin/ or aliases
    functions = {
      # Nix shortcuts - minimal versions
      nb = ''
        pushd ~/darwin-config > /dev/null
        nix run .#build $argv
        popd > /dev/null
      '';
      
      ns = ''
        ns-ghostty-safe $argv
      '';

      # Yazi directory changing (official wrapper) - needed for proper integration
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';
    };

    # Minimal abbreviations - just the essentials
    shellAbbrs = {
      # Better tools
      ls = "eza --icons --group-directories-first";
      ll = "eza --icons --group-directories-first -la --grid --header --git";
      cat = "bat --style=plain";
      grep = "rg";
      
      # Git essentials
      gst = "git status --short --branch";
      gp = "git pull";
      
      # Useful aliases
      diff = "difft";
    };
  };
}