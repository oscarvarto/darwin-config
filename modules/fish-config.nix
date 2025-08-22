{ config, pkgs, lib, user, pathConfig ? null, ... }:

{
  programs.fish = {
    enable = true;
    shellInit = ''
      # Nix daemon initialization (equivalent to Nushell initialization)
      if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          set -gx NIX_SSL_CERT_FILE '/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt'
          set -gx NIX_PROFILES '/nix/var/nix/profiles/default ~/.nix-profile'
          set -gx NIX_PATH 'nixpkgs=flake:nixpkgs'
          fish_add_path --prepend '/nix/var/nix/profiles/default/bin'
      end

      # Environment variables (matching nushell env.nu)
      set -gx AWS_REGION "us-east-1"
      set -gx AWS_DEFAULT_REGION "us-east-1"
      set -gx DOTNET_ROOT "/usr/local/share/dotnet"
      set -gx EMACSDIR "~/.emacs.d"
      set -gx DOOMDIR "~/.doom.d"
      set -gx DOOMLOCALDIR "~/.emacs.d/.local"
      set -gx CARGO_HOME "$HOME/.cargo"
      
      # Set Xcode developer directory to beta version
      set -gx DEVELOPER_DIR "/Applications/Xcode-beta.app/Contents/Developer"

      # Enchant/Aspell configuration (matching nushell)
      set -gx ENCHANT_ORDERING 'en:aspell,es:aspell,*:aspell'
      set -gx ASPELL_CONF 'dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [ en en-computers en-science es ])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell'

      # Use centralized PATH configuration from modules/path-config.nix
      ${pathConfig.fish.pathSetup or "# PATH config not available"}

      # Editor configuration
      set -gx EDITOR "nvim"
      
      # Load Zellij theme override if available
      if test -f ~/.cache/zellij_theme_config
          source ~/.cache/zellij_theme_config
      end
      
      # Load theme from cache file set by catppuccin theme switcher
      if test -f ~/.cache/fish_theme
          set -gx FISH_THEME (cat ~/.cache/fish_theme 2>/dev/null | string trim)
      else
          set -gx FISH_THEME "dark"
      end
      
      # Set LS_COLORS and BAT_THEME based on fish theme
      if test "$FISH_THEME" = "light"
          # Light theme LS_COLORS (higher contrast for light backgrounds)
          set -gx LS_COLORS "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36"
          set -gx BAT_THEME "GitHub"
      else
          # Dark theme LS_COLORS (higher contrast for dark backgrounds)
          set -gx LS_COLORS "rs=0:di=01;94:ln=01;96:mh=00:pi=40;93:so=01;95:do=01;95:bd=40;93;01:cd=40;93;01:or=40;91;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=94;42:st=37;44:ex=01;92:*.tar=01;91:*.tgz=01;91:*.arc=01;91:*.arj=01;91:*.taz=01;91:*.lha=01;91:*.lz4=01;91:*.lzh=01;91:*.lzma=01;91:*.tlz=01;91:*.txz=01;91:*.tzo=01;91:*.t7z=01;91:*.zip=01;91:*.z=01;91:*.Z=01;91:*.dz=01;91:*.gz=01;91:*.lrz=01;91:*.lz=01;91:*.lzo=01;91:*.xz=01;91:*.bz2=01;91:*.bz=01;91:*.tbz=01;91:*.tbz2=01;91:*.tz=01;91:*.deb=01;91:*.rpm=01;91:*.jar=01;91:*.war=01;91:*.ear=01;91:*.sar=01;91:*.rar=01;91:*.alz=01;91:*.ace=01;91:*.zoo=01;91:*.cpio=01;91:*.7z=01;91:*.rz=01;91:*.cab=01;91:*.jpg=01;95:*.jpeg=01;95:*.gif=01;95:*.bmp=01;95:*.pbm=01;95:*.pgm=01;95:*.ppm=01;95:*.tga=01;95:*.xbm=01;95:*.xpm=01;95:*.tif=01;95:*.tiff=01;95:*.png=01;95:*.svg=01;95:*.svgz=01;95:*.mng=01;95:*.pcx=01;95:*.mov=01;95:*.mpg=01;95:*.mpeg=01;95:*.m2v=01;95:*.mkv=01;95:*.webm=01;95:*.ogm=01;95:*.mp4=01;95:*.m4v=01;95:*.mp4v=01;95:*.vob=01;95:*.qt=01;95:*.nuv=01;95:*.wmv=01;95:*.asf=01;95:*.rm=01;95:*.rmvb=01;95:*.flc=01;95:*.avi=01;95:*.fli=01;95:*.flv=01;95:*.gl=01;95:*.dl=01;95:*.xcf=01;95:*.xwd=01;95:*.yuv=01;95:*.cgm=01;95:*.emf=01;95:*.ogv=01;95:*.ogx=01;95:*.aac=00;96:*.au=00;96:*.flac=00;96:*.m4a=00;96:*.mid=00;96:*.midi=00;96:*.mka=00;96:*.mp3=00;96:*.mpc=00;96:*.ogg=00;96:*.ra=00;96:*.wav=00;96:*.oga=00;96:*.opus=00;96:*.spx=00;96:*.xspf=00;96"
          set -gx BAT_THEME "ansi"
      end
    '';

    # Interactive configuration
    interactiveShellInit = ''
      # Vi mode (matching nushell's vi edit mode)
      fish_vi_key_bindings

      # Let Starship handle the prompt - no custom fish_prompt function
      # This allows starship.toml configuration to work properly
      
      # Set Fish syntax highlighting colors based on theme
      if test "$FISH_THEME" = "light"
          # Light theme Fish colors (higher contrast for light backgrounds)
          set -g fish_color_normal "333333"                  # normal text - dark gray
          set -g fish_color_command "0066cc"                # commands - blue
          set -g fish_color_keyword "990099"                # keywords - purple
          set -g fish_color_quote "009900"                  # quoted text - green
          set -g fish_color_redirection "cc6600"            # redirections - orange
          set -g fish_color_end "cc0000"                    # command separators - red
          set -g fish_color_error "cc0000" --bold          # errors - bold red
          set -g fish_color_param "666666"                 # parameters - medium gray
          set -g fish_color_comment "999999"               # comments - light gray
          set -g fish_color_match --background="ffff00"     # matching brackets - yellow background
          set -g fish_color_selection --background="e6e6e6" # selected text - light gray background
          set -g fish_color_search_match --background="ffff99" # search matches - light yellow background
          set -g fish_color_history_current --bold         # current history item
          set -g fish_color_operator "cc6600"              # operators - orange
          set -g fish_color_escape "009999"                # escape sequences - cyan
          set -g fish_color_cwd "0066cc"                   # current directory - blue
          set -g fish_color_cwd_root "cc0000"              # root directory - red
          set -g fish_color_valid_path --underline        # valid paths - underlined
          set -g fish_color_autosuggestion "cccccc"        # autosuggestions - very light gray
          set -g fish_color_user "009900"                  # username - green
          set -g fish_color_host "0066cc"                  # hostname - blue
      else
          # Dark theme Fish colors (higher contrast for dark backgrounds)
          set -g fish_color_normal "ffffff"                # normal text - white
          set -g fish_color_command "66b3ff"              # commands - light blue
          set -g fish_color_keyword "ff66ff"              # keywords - magenta
          set -g fish_color_quote "66ff66"                # quoted text - light green
          set -g fish_color_redirection "ffaa66"          # redirections - light orange
          set -g fish_color_end "ff6666"                  # command separators - light red
          set -g fish_color_error "ff6666" --bold        # errors - bold light red
          set -g fish_color_param "cccccc"               # parameters - light gray
          set -g fish_color_comment "888888"             # comments - medium gray
          set -g fish_color_match --background="666600"   # matching brackets - dark yellow background
          set -g fish_color_selection --background="444444" # selected text - dark gray background
          set -g fish_color_search_match --background="666633" # search matches - dark yellow background
          set -g fish_color_history_current --bold       # current history item
          set -g fish_color_operator "ffaa66"            # operators - light orange
          set -g fish_color_escape "66ffff"              # escape sequences - light cyan
          set -g fish_color_cwd "66b3ff"                 # current directory - light blue
          set -g fish_color_cwd_root "ff6666"            # root directory - light red
          set -g fish_color_valid_path --underline      # valid paths - underlined
          set -g fish_color_autosuggestion "666666"      # autosuggestions - medium gray
          set -g fish_color_user "66ff66"                # username - light green
          set -g fish_color_host "66b3ff"                # hostname - light blue
      end
      
      # Authoritative PATH override - ensures our configuration takes precedence over all tools
      ${pathConfig.fish.pathOverride or "# PATH override not available"}
      
      # Claude Code integration - Shift+Enter key binding
      # The escape sequence \e[13;2u is for Shift+Enter in modern terminals
      bind -M insert \e[13;2u 'echo "# Claude Code: Submit prompt"'
      bind -M default \e[13;2u 'echo "# Claude Code: Submit prompt"'
    '';

    # Function definitions (matching some nushell functions)
    functions = {
      # Equivalent to nushell's gp function
      gp = ''
        git fetch --all -p
        git pull
        git submodule update --recursive
      '';
      
      # Equivalent to nushell's search alias  
      search = ''
        rg -p --glob '!node_modules/*' $argv
      '';
      
      # Equivalent to nushell's diff alias
      diff = ''
        difft $argv
      '';

      # Nix shortcuts (matching nushell)
      nb = ''
        pushd ~/darwin-config
        nix run .#build
        popd
      '';
      
      ns = ''
        pushd ~/darwin-config
        nix run .#build-switch  
        popd
      '';

      # Terminal and editor shortcuts (matching nushell aliases)
      tg = ''
        $EDITOR ~/.config/ghostty/config
      '';
      
      tgg = ''
        $EDITOR ~/.config/ghostty/overrides.conf
      '';
      
      nnc = ''
        $EDITOR ~/darwin-config/modules/nushell/config.nu
      '';
      
      nne = ''
        $EDITOR ~/darwin-config/modules/nushell/env.nu
      '';

      # Fish config editing (in home-manager.nix)
      ffc = ''
        $EDITOR ~/darwin-config/modules/home-manager.nix
      '';
      
      # Manual catppuccin theme switching
      catppuccin-theme-switch = ''
        ~/.local/bin/catppuccin-theme-switcher
      '';
      
      # Official yazi shell wrapper for directory changing
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';
    };

    # Abbreviations (like aliases but expandable)
    shellAbbrs = {
      # Doom Emacs shortcuts (matching nushell)
      ds = "doom sync --aot --gc -j (nproc)";
      dup = "doom sync -u --aot --gc -j (nproc)";
      sdup = "doom sync -u --aot --gc -j (nproc) --rebuild";
      
      # Emacs shortcuts
      edd = "emacs --daemon=doom";
      pke = "pkill -9 Emacs";
      tt = "emacs -nw";
      
      # Quick navigation
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      
      # Git shortcuts
      g = "git";
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gs = "git status";
      gd = "git diff";
      gl = "git log";
    };
  };
}