{ config, pkgs, lib, user ? "oscarvarto", ... }:

let 
  # user is passed as parameter or falls back to default
in
{
  programs = {
    # Shared shell utilities
    broot = {
      enable = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    # Consolidated zsh configuration for macOS
    zsh = {
      enable = true;
      autocd = false;
      cdpath = [ "~/.local/share/src" ];
      plugins = [ ];
      
      # Base configuration that works everywhere
      initContent = lib.mkAfter ''
        # Nix daemon setup
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi

        export LC_ALL="en_US.UTF-8"
        bindkey "^[[3~" delete-char

        # Set Xcode developer directory to beta version
        export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"

        # Define variables for directories
        export EMACSDIR=$HOME/.emacs.d
        export DOOMDIR=$HOME/.doom.d
        export DOOMLOCALDIR=$HOME/.emacs.d/.local

        # Add Maven 4 to PATH first (before Homebrew Maven 3.9.11)
        # PATH="$HOME/mvn4/apache-maven-4.0.0-rc-4/bin:$PATH"
        PATH="$HOME/darwin-config/modules/elisp-formatter:$PATH"
        PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
        PATH=$HOME/.local/share/bin:$PATH
        PATH=$HOME/.local/bin:$PATH
        PATH=$HOME/.cargo/bin:$PATH
        PATH=$EMACSDIR/bin:$PATH
        PATH=$HOME/bin:$PATH
        PATH="$HOME/Library/Application Support/Coursier/bin:$PATH"

        export PATH="$HOME/.volta/bin:$PATH"

        # Remove history data we don't want to see
        export HISTIGNORE="pwd:ls:cd"

        # Ripgrep alias
        alias search=rg -p --glob '!node_modules/*' $@

        export ALTERNATE_EDITOR=""
        export EDITOR="nvim"
        export VISUAL="/opt/homebrew/bin/emacsclient -nc -s /var/folders/yh/5_g54kd572gd9vr8tbc4m6gh0000gn/T/emacs501/doom"

        # Load theme from cache file set by catppuccin theme switcher
        if [[ -f ~/.cache/zsh_theme ]]; then
            export ZSH_THEME=$(cat ~/.cache/zsh_theme 2>/dev/null | tr -d '\n')
        else
            export ZSH_THEME="dark"
        fi

        t() {
           # nvim "$@"
           /opt/homebrew/bin/emacsclient -nw -s /var/folders/yh/5_g54kd572gd9vr8tbc4m6gh0000gn/T/emacs501/doom "$@"
        }

        ec() {
           /opt/homebrew/bin/emacsclient -nc -s /var/folders/yh/5_g54kd572gd9vr8tbc4m6gh0000gn/T/emacs501/doom "$@"
        }

        e() {
           emacs & disown
        }

        # nix shortcuts
        shell() {
            nix-shell '<nixpkgs>' -A "$1"
        }

        # Source shell functions from external file
        if [[ -f "$HOME/darwin-config/modules/shell-functions.sh" ]]; then
            source "$HOME/darwin-config/modules/shell-functions.sh"
        fi

        # Always color ls and group directories
        alias ls='ls --color=auto'
 
        alias tg="$EDITOR $HOME/.config/ghostty/config"
        alias edd="emacs --daemon=doom"
 
        alias pke="pkill -9 Emacs"
        alias nz="nvim ~/.zshrc"
        alias gd="ghostty +show-config --default --docs"
        alias gp="git fetch --all -p; git pull; git submodule update --recursive"
        alias ds="doom sync --aot --gc -j \\$(nproc)"
        alias dup="doom sync -u --aot --gc -j \\$(nproc)"
        alias diff="difft"
        alias nb="pushd \\$HOME/darwin-config > /dev/null; nix run .#build; popd > /dev/null"
        alias ns="pushd \\$HOME/darwin-config > /dev/null; nix run .#build-switch; popd > /dev/null"
        
        # Claude Code integration - Shift+Enter key binding
        # Function to handle Claude Code prompt submission
        claude-code-submit() {
          echo "# Claude Code: Submit prompt"
        }
        zle -N claude-code-submit
        
        # Bind Shift+Enter to the Claude Code submit function
        # The escape sequence \\e[13;2u is for Shift+Enter in modern terminals
        bindkey '^[[13;2u' claude-code-submit
      '';
    };
  };
}
