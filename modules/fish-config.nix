{
  config,
  pkgs,
  lib,
  pathConfig ? null,
  darwinConfigPath ? "",
  ...
}: let
  cfg = config.local.fish;
  inherit (lib) mkEnableOption mkIf mkAfter;

  # Secrets loader for fish (parses LazyVim secrets.lua)
  secretsFile = "${darwinConfigPath}/stow/lazyvim/.config/nvim/secrets.lua";
  fishSecretsLoader = ''
    # Load API keys from LazyVim secrets.lua (not tracked in git)
    if test -f "${secretsFile}"
      # Parse the Lua table format
      for line in (cat "${secretsFile}")
        # Match lines like: KEY = "value", or KEY = 'value',
        set -l match (string match -r '^[[:space:]]*([A-Z_][A-Z0-9_]*)[[:space:]]*=[[:space:]]*["\x27](.*)[\"\x27][[:space:]]*,?[[:space:]]*$' -- $line)
        if test (count $match) -gt 2
          set -gx $match[2] $match[3]
        end
      end
    end
  '';
in {
  options.local.fish = {
    enable = mkEnableOption "fish shell";
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;

      # Login shell initialization - centralized PATH + environment setup
      loginShellInit = ''
        # Fix for macOS libcrypto "poisoning" - ensures Nix's OpenSSL is loaded
        # instead of the system's abort()-ing stub (see: https://github.com/NixOS/nixpkgs/issues/160258)
        set -gx DYLD_LIBRARY_PATH '${pkgs.openssl.out}/lib'

        # Set ASPELL_CONF with Nix paths (must be set in Nix context)
        set -gx ASPELL_CONF 'dict-dir ${pkgs.aspellWithDicts (dicts: with dicts; [en en-computers en-science es])}/lib/aspell; data-dir ${pkgs.aspell}/share/aspell'

        # Nix daemon initialization
        if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          set -gx NIX_SSL_CERT_FILE '/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt'
          set -gx NIX_PROFILES '/nix/var/nix/profiles/default ~/.nix-profile'
          set -gx NIX_PATH 'nixpkgs=flake:nixpkgs'
        end

        # Environment variables (matching zsh setup)
        set -gx DOTNET_ROOT "/usr/local/share/dotnet"
        set -gx EMACSDIR "$HOME/.emacs.d"
        set -gx CARGO_HOME "$HOME/.cargo"
        set -gx DARWIN_CONFIG_PATH "${darwinConfigPath}"
        set -gx VCPKG_ROOT "$HOME/git-repos/vcpkg"

        # Set Xcode developer directory to release version (matching zsh)
        set -gx DEVELOPER_DIR "/Applications/Xcode.app/Contents/Developer"

        # SDK path configuration (matching zsh)
        set -gx SDKROOT (xcrun --sdk macosx --show-sdk-path 2>/dev/null || echo "")
        set -gx MACOSX_DEPLOYMENT_TARGET "26.0"

        # Enchant/Aspell configuration
        set -gx ENCHANT_ORDERING 'en:aspell,es:aspell,*:aspell'

        # Editor configuration (matching zsh)
        set -gx ALTERNATE_EDITOR "false"
        set -gx EDITOR "nvim"
        set -gx VISUAL "code-insiders -w"

        ${fishSecretsLoader}

        # Apply centralized PATH configuration if available
        ${
          if pathConfig != null
          then pathConfig.fish.pathSetup
          else ""
        }
      '';

      # Interactive shell initialization
      interactiveShellInit = ''
        # Initialize carapace for enhanced completions (must be early)
        if command -v carapace >/dev/null 2>&1
          carapace _carapace | source
        end

        # Load theme from cache file set by catppuccin theme switcher
        if test -f ~/.cache/fish_theme
          set -gx FISH_THEME (cat ~/.cache/fish_theme 2>/dev/null | string trim)
        else
          set -gx FISH_THEME "dark"
        end

        # Load Zellij theme config if available (matching zsh configuration)
        if test -f ~/.cache/zellij_theme_config
          source ~/.cache/zellij_theme_config
        end

        # Set LS_COLORS and BAT_THEME based on fish theme
        if test "$FISH_THEME" = "light"
          # Light theme colors
          set -gx LS_COLORS "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32"
          set -gx BAT_THEME "GitHub"
        else
          # Dark theme colors
          set -gx LS_COLORS "rs=0:di=01;94:ln=01;96:mh=00:pi=40;93:so=01;95:do=01;95:bd=40;93;01:cd=40;93;01:or=40;91;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=94;42:st=37;44:ex=01;92"
          set -gx BAT_THEME "ansi"
        end

        # Set Fish syntax highlighting colors based on theme
        if test "$FISH_THEME" = "light"
          # Light theme Fish colors (higher contrast for light backgrounds)
          set -g fish_color_normal "333333"
          set -g fish_color_command "0066cc"
          set -g fish_color_keyword "990099"
          set -g fish_color_quote "009900"
          set -g fish_color_redirection "cc6600"
          set -g fish_color_end "cc0000"
          set -g fish_color_error "cc0000" --bold
          set -g fish_color_param "666666"
          set -g fish_color_comment "999999"
          set -g fish_color_autosuggestion "cccccc"
        else
          # Dark theme Fish colors (higher contrast for dark backgrounds)
          set -g fish_color_normal "ffffff"
          set -g fish_color_command "66b3ff"
          set -g fish_color_keyword "ff66ff"
          set -g fish_color_quote "66ff66"
          set -g fish_color_redirection "ffaa66"
          set -g fish_color_end "ff6666"
          set -g fish_color_error "ff6666" --bold
          set -g fish_color_param "cccccc"
          set -g fish_color_comment "888888"
          set -g fish_color_autosuggestion "666666"
        end

        # History settings (matching other shells)
        set -g fish_history_max 50000

        # Completion settings for better autocomplete experience
        set -g fish_complete_path $fish_complete_path
        set -g fish_autosuggestion_enabled 1

        # Ghostty terminal compatibility fallback (matching zsh)
        if test "$TERM" = "xterm-ghostty"
          if not command -v infocmp >/dev/null 2>&1; or not infocmp xterm-ghostty >/dev/null 2>&1
            set -gx TERM "xterm-256color"
          end
        end

        # Authoritative PATH override - ensures our configuration takes precedence over all tools
        ${
          if pathConfig != null
          then pathConfig.fish.pathOverride
          else ""
        }

        # YAZELIX START v4 - Yazelix managed configuration (do not modify this comment)
        # delete this whole section to re-generate the config, if needed
        if test -n "$IN_YAZELIX_SHELL"
          source "$HOME/.config/yazelix/shells/fish/yazelix_fish_config.fish"
        end
        # yzx command - always available for launching/managing yazelix
        function yzx --description "Yazelix command suite"
            nu -c "use ~/.config/yazelix/nushell/scripts/core/yazelix.nu *; yzx $argv"
        end
        function yzh --description "Yazelix launch here"
            yzx launch --here
        end
        # YAZELIX END v4 - Yazelix managed configuration (do not modify this comment)

        # Initialize atuin if available (matching zsh)
        if command -v atuin >/dev/null 2>&1
          atuin init fish | source
        end

        # JIRA API token is available on-demand via get-jira-api-token command
        # To set it manually: set -gx JIRA_API_TOKEN (get-jira-api-token work)
        # This avoids 1Password biometric prompts on every shell startup
      '';

      # Function definitions (matching zsh functionality)
      functions = {
        # Nix shortcuts (matching zsh)
        nb = ''
          set -l verbose false
          if test "$argv[1]" = "-v"
            set verbose true
            set -e argv[1]
          end

          pushd $DARWIN_CONFIG_PATH >/dev/null

          if test $verbose = true
            nix run .#build -- --verbose $argv
          else
            nix run .#build -- $argv
          end

          popd >/dev/null
        '';

        ns = ''
          set -l verbose false
          if test "$argv[1]" = "-v"
            set verbose true
            set -e argv[1]
          end

          if test $verbose = true
            ns-ghostty-safe -v $argv
          else
            ns-ghostty-safe $argv
          end
        '';

        shell = ''
          nix-shell '<nixpkgs>' -A $argv[1]
        '';

        # Yazi directory changing (official wrapper - matching zsh)
        y = ''
          set tmp (mktemp -t "yazi-cwd.XXXXXX")
          yazi $argv --cwd-file="$tmp"
          if read -z cwd <"$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
            builtin cd -- "$cwd"
          end
          rm -f -- "$tmp"
        '';

        # JSON viewing with jq and bat (matching zsh)
        jqc = ''
          jq -C $argv | bat --style=plain --language=json
        '';

        # jank wrapper to clear Nix SDK variables (matching zsh)
        jank = ''
          set -l SDKROOT (xcrun --sdk macosx --show-sdk-path)
          set -l DEVELOPER_DIR "/Applications/Xcode.app/Contents/Developer"

          # Clear Nix-provided compiler flags
          set -e NIX_CFLAGS_COMPILE
          set -e NIX_LDFLAGS
          set -e NIX_APPLE_SDK_VERSION

          # Run jank with clean SDK environment
          env SDKROOT="$SDKROOT" DEVELOPER_DIR="$DEVELOPER_DIR" /opt/homebrew/bin/jank $argv
        '';

        # Pixi environment with graph-tool (conda-forge + PyPI)
        # Usage: pixi-gt shell, pixi-gt run python, etc.
        pixi-gt = ''
          set cmd $argv[1]
          set -e argv[1]
          pixi $cmd --manifest-path ~/darwin-config/python-env/pixi.toml $argv
        '';
      };

      # Abbreviations (matching zsh aliases)
      shellAbbrs = {
        # Search
        search = "rg -p --glob '!node_modules/*'";

        # Better ls (eza) - matching zsh
        lls = "eza --icons --group-directories-first";
        ll = "eza --icons --group-directories-first -la --grid --header --git";
        ltt = "eza --icons --group-directories-first -la --tree --level=2";
        llt = "eza --icons --group-directories-first -la --tree";
        lx = "eza --icons --group-directories-first -la --sort=extension";
        lk = "eza --icons --group-directories-first -la --sort=size --reverse";
        lc = "eza --icons --group-directories-first -la --sort=changed --reverse";
        lm = "eza --icons --group-directories-first -la --sort=modified --reverse";

        # Process viewer (matching zsh)
        ps = "procs";
        pst = "procs --tree";

        # Disk usage (matching zsh)
        dua = "dust -r";

        # Better cat/bat (matching zsh)
        catn = "bat --style=numbers";
        catf = "bat --style=full";

        # Better grep (matching zsh)
        grepi = "rg -i";
        grepl = "rg -l";

        # Git commands (matching zsh)
        glog = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        gst = "git status --short --branch";
        gp = "git fetch --all -p; git pull; git submodule update --recursive";

        # Code statistics (matching zsh)
        loc = "tokei";
        locs = "tokei --sort lines";

        # Hex viewer (matching zsh)
        hex = "hexyl";

        # Diff tool (matching zsh)
        diff = "difft";

        # Benchmarking (matching zsh)
        bench = "hyperfine";

        # String replacement (matching zsh)
        replace = "sd";

        # Emacs shortcuts (using scripts in ~/.local/share/bin/)
        t = "$HOME/.local/share/bin/t";
        e = "$HOME/.local/share/bin/e";
        tt = "$HOME/.local/share/bin/tt";
        edd = "$HOME/.local/share/bin/edd";
        et = "$HOME/.local/share/bin/et";
        ke = "$HOME/.local/share/bin/ke";
        pke = "pkill -9 Emacs";

        # Config editing shortcuts (matching zsh)
        tg = "$EDITOR $HOME/.config/ghostty/config";
        nz = "nvim ~/.zshrc";

        # Ghostty shortcuts (matching zsh)
        gdoc = "ghostty +show-config --default --docs";

        avante = "nvim -c \"lua vim.defer_fn(function()require('avante.api').zen_mode()end, 100)\"";

        # Quick access to xonsh shell via pixi environment
        xsh = "pixi-gt run xonsh";
      };
    };
  };
}
