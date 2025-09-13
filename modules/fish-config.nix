{ config, pkgs, lib, pathConfig, ... }:

{
  programs.fish = {
    enable = true;
    
    # Login shell initialization - use centralized PATH + custom config
    loginShellInit = ''
      # Set ASPELL_CONF with Nix paths (must be set in Nix context)
      set -gx ASPELL_CONF 'dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell'
      
      # Apply centralized PATH configuration
      ${pathConfig.fish.pathSetup}
      
      # Source the main login configuration
      source ~/darwin-config/fish-login-init.fish
    '';

    # Interactive shell initialization - source perfectly formatted file
    interactiveShellInit = ''
      # Source the main interactive configuration
      source ~/darwin-config/fish-interactive-init.fish
      
      # Authoritative PATH override - ensures our configuration takes precedence over all tools
      ${pathConfig.fish.pathOverride}
    '';

    # Function definitions (equivalent to nushell functions and zsh aliases)
    functions = {
      # Git operations (matching current aliases)
      gp = ''
        git fetch --all -p
        git pull
        git submodule update --recursive
      '';
      
      # Search function (matching current setup)
      search = ''
        rg -p --glob '!node_modules/*' $argv
      '';

      # Nix shortcuts (matching current setup) - enhanced with -v flag support
      nb = ''
        set -l verbose false
        set -l args
        
        for arg in $argv
            if test "$arg" = "-v"
                set verbose true
            else
                set args $args $arg
            end
        end
        
        pushd ~/darwin-config > /dev/null
        
        if test $verbose = true
            nix run .#build --verbose $args
        else
            nix run .#build $args
        end
        
        popd > /dev/null
      '';
      
      ns = ''
        set -l verbose false
        set -l args
        
        for arg in $argv
            if test "$arg" = "-v"
                set verbose true
            else
                set args $args $arg
            end
        end
        
        if test $verbose = true
            ns-ghostty-safe -v $args
        else
            ns-ghostty-safe $args
        end
      '';

      # Terminal and editor shortcuts (matching current zsh aliases)
      tg = ''
        $EDITOR ~/.config/ghostty/config
      '';
      
      nnc = ''
        $EDITOR ~/darwin-config/modules/nushell/config.nu
      '';
      
      nne = ''
        $EDITOR ~/darwin-config/modules/nushell/env.nu
      '';

      # Fish config editing
      ffc = ''
        $EDITOR ~/darwin-config/modules/fish-config.nix
      '';
      
      # Emacs functions - Fish implementations equivalent to nushell
      # Source the helper functions first
      "__fish_emacs_init" = ''
        source ~/darwin-config/fish-emacs-functions.fish
      '';
      
      # Terminal Emacs function
      t = ''
        set -l socket_path (ensure-emacs-daemon)
        if test $status -ne 0
            return 1
        end
        env SHELL=/bin/zsh ~/.nix-profile/bin/emacsclient -nw -s "$socket_path" $argv
      '';
      
      # GUI Emacs client function
      e = ''
        set -l socket_path (ensure-emacs-daemon)
        if test $status -ne 0
            return 1
        end
        env SHELL=/bin/zsh ~/.nix-profile/bin/emacsclient -nc -s "$socket_path" $argv
      '';
      
      # Direct terminal Emacs (no daemon)
      tt = ''
        env SHELL=/bin/zsh emacs -nw $argv
      '';
      
      # Background Emacs
      et = ''
        set -l tag "emacs"
        if test (count $argv) -gt 0
            set tag $argv[1]
        end
        
        nohup emacs >/dev/null 2>&1 &
        set -l pid $last_pid
        
        echo "Started Emacs with PID $pid (tag: $tag)"
        echo "$pid:$tag" >> ~/.emacs_jobs
      '';
      
      # Kill Emacs processes
      ke = ''
        ~/.local/share/bin/ke $argv
      '';
      
      pke = ''
        pkill -9 Emacs
      '';

      # Yazi directory changing (official wrapper)
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';
    };

    # Abbreviations (equivalent to aliases)
    shellAbbrs = {
      # Doom Emacs shortcuts (matching current setup)
      ds = "doom sync --aot --gc -j (nproc)";
      dup = "doom sync -u --aot --gc -j (nproc)";
      
      # Emacs shortcuts (note: ke, pke are scripts in ~/.local/share/bin/, not abbreviations)
      edd = "emacs --daemon=doom";
      
      # Better tools (matching current zsh setup)
      ls = "eza --icons --group-directories-first";
      ll = "eza --icons --group-directories-first -la --grid --header --git";
      lt = "eza --icons --group-directories-first -la --tree --level=2";
      cat = "bat --style=plain";
      grep = "rg";
      
      # Git shortcuts
      gst = "git status --short --branch";
      glog = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      
      # System monitoring (matching current setup)
      ps = "procs";
      du = "dust";
      
      # Other useful aliases
      diff = "difft";
      hex = "hexyl";
      loc = "tokei";
    };
  };
}