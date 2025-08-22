{ config, pkgs, lib, user ? "oscarvarto", ... }:

let 
  # user is passed as parameter or falls back to default
in
{
  programs = {
    # Shared shell utilities
    broot = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    # direnv is now managed directly in home-manager.nix to avoid conflicts

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    # Consolidated zsh configuration for macOS
    zsh = {
      enable = true;
      autocd = false;
      cdpath = [ "~/.local/share/src" ];
      plugins = [ ];
      
      # Enhanced completion settings
      completionInit = ''
        # Enable completion system
        autoload -Uz compinit && compinit
        
        # Enhanced completion settings for Fish-like experience
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' completer _extensions _complete _approximate
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.zsh/cache
        
        # Better directory completion
        zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
        
        # Git completion improvements
        zstyle ':completion:*:git-checkout:*' sort false
        
        # Load additional completions
        if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
          fpath+=(/opt/homebrew/share/zsh/site-functions)
        fi
        
        if [[ -d /usr/local/share/zsh/site-functions ]]; then
          fpath+=(/usr/local/share/zsh/site-functions)
        fi
      '';
      
      # Base configuration that works everywhere
      initContent = lib.mkAfter ''
        # Nix daemon setup
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi
        
        # Load zsh plugins
        # Autosuggestions plugin for fish-like suggestions
        if [[ -f ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        fi
        
        # Syntax highlighting plugin for colored commands
        if [[ -f ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
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
        # VISUAL will use dynamic socket finding via ec function
        export VISUAL="/opt/homebrew/bin/emacsclient -nc"

        # Load theme from cache file set by catppuccin theme switcher
        if [[ -f ~/.cache/zsh_theme ]]; then
            export ZSH_THEME=$(cat ~/.cache/zsh_theme 2>/dev/null | tr -d '\n')
        else
            export ZSH_THEME="dark"
        fi

        # Function to dynamically find the Emacs daemon socket
        get_emacs_socket() {
            local socket_path=""
            # First try to find the doom socket in temp directories
            if command -v fd >/dev/null 2>&1; then
                socket_path=$(fd -t s "doom" /var/folders 2>/dev/null | head -1)
            fi
            # Fallback to standard location using TMPDIR
            if [[ -z "$socket_path" ]]; then
                socket_path="''${TMPDIR}emacs$(id -u)/doom"
            fi
            echo "$socket_path"
        }

        # Function to ensure Emacs daemon is running
        ensure_emacs_daemon() {
            local socket=$(get_emacs_socket)
            if [[ ! -S "$socket" ]]; then
                echo "Emacs daemon not running. Starting..."
                doom run --daemon=doom >/dev/null 2>&1 || emacs --daemon=doom
                sleep 1
                socket=$(get_emacs_socket)
            fi
            echo "$socket"
        }

        t() {
           local socket=$(ensure_emacs_daemon)
           if [[ -S "$socket" ]]; then
               /opt/homebrew/bin/emacsclient -nw -s "$socket" "$@"
           else
               echo "Error: Could not connect to Emacs daemon"
               return 1
           fi
        }

        ec() {
           local socket=$(ensure_emacs_daemon)
           if [[ -S "$socket" ]]; then
               /opt/homebrew/bin/emacsclient -nc -s "$socket" "$@"
           else
               echo "Error: Could not connect to Emacs daemon"
               return 1
           fi
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

        # Table-like output commands (similar to nushell)
        # Using eza for better ls output with icons and colors
        alias ls='eza --icons --group-directories-first'
        alias ll='eza --icons --group-directories-first -la --grid --header --git'
        alias lt='eza --icons --group-directories-first -la --tree --level=2'
        alias llt='eza --icons --group-directories-first -la --tree'
        alias lx='eza --icons --group-directories-first -la --sort=extension'
        alias lk='eza --icons --group-directories-first -la --sort=size --reverse'
        alias lc='eza --icons --group-directories-first -la --sort=changed --reverse'
        alias lm='eza --icons --group-directories-first -la --sort=modified --reverse'
        
        # Process viewer with better formatting
        alias ps='procs'
        alias pst='procs --tree'
        alias psg='procs | rg'
        
        # Disk usage with better formatting
        alias du='dust'
        alias dua='dust -r'
        
        # System information in table format
        alias sysinfo='btm --basic --default_widget_type=cpu'
        
        # Network connections in table format
        alias netstat='bandwhich'
        
        # File finding with preview
        alias ff='fd --type f --hidden --follow --exclude .git | fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
        
        # Directory navigation with preview
        alias fcd='cd $(fd --type d --hidden --follow --exclude .git | fzf --preview "eza --icons --tree --level=1 --color=always {}")'
        
        # Git commands with better output
        alias glog='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
        alias gst='git status --short --branch'
        
        # Better cat/bat aliases
        alias cat='bat --style=plain'
        alias catn='bat --style=numbers'
        alias catf='bat --style=full'
        
        # Code statistics
        alias loc='tokei'
        alias locs='tokei --sort lines'
        
        # Hex viewer
        alias hex='hexyl'
        
        # Better grep with ripgrep
        alias grep='rg'
        alias grepi='rg -i'
        alias grepl='rg -l'
        
        # Benchmarking
        alias bench='hyperfine'
        
        # String replacement
        alias replace='sd'
        
        # Initialize zoxide for smarter cd
        eval "$(zoxide init zsh)"
        alias cd='z'
        alias cdi='zi'  # Interactive selection
        
        # Function to show directory contents automatically when changing directories
        chpwd() {
            eza --icons --group-directories-first -la --grid --header --git
        }
        
        # Function for JSON viewing with jq and bat
        jqc() {
            jq -C "$@" | bat --style=plain --language=json
        }
        
        # Function to show system info in a nice format
        info() {
            echo "\n📊 System Information:"
            echo "========================"
            neofetch --off --color_blocks off | tail -n +2
            echo "\n💾 Disk Usage:"
            echo "========================"
            dust -d 1
            echo "\n🔄 Top Processes:"
            echo "========================"
            procs --top 10 --sortd cpu
        }
 
        alias tg="$EDITOR $HOME/.config/ghostty/config"
        alias edd="emacs --daemon=doom"
        alias eddr="doom run --daemon=doom"  # Alternative daemon start method
 
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
        # The escape sequence \\\\e[13;2u is for Shift+Enter in modern terminals
        bindkey '^[[13;2u' claude-code-submit
        
        # Atuin handles history search - removing conflicting bindings
        # Atuin uses Ctrl+R for interactive search and up/down arrows for history navigation
        # The Atuin integration from home-manager will set up the proper bindings
        
        # Basic navigation that doesn't conflict with Atuin
        bindkey '^F' forward-char     # Ctrl+F forward one character
        bindkey '^B' backward-char    # Ctrl+B backward one character
        bindkey '^E' end-of-line      # Ctrl+E to end of line
        bindkey '^A' beginning-of-line # Ctrl+A to beginning of line
        
        # Better word navigation
        bindkey '^[[1;5C' forward-word  # Ctrl+Right
        bindkey '^[[1;5D' backward-word # Ctrl+Left
        bindkey '^[f' forward-word      # Alt+F
        bindkey '^[b' backward-word     # Alt+B
        
        # Set autosuggestion highlight style (gray text like Fish)
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)
        ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
        ZSH_AUTOSUGGEST_USE_ASYNC=true
        
        # Enable highlighting of commands (like Fish)
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
        
        # Better history settings
        HISTSIZE=50000
        SAVEHIST=50000
        setopt EXTENDED_HISTORY          # Write timestamp to history
        setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first
        setopt HIST_IGNORE_DUPS          # Don't record duplicates
        setopt HIST_IGNORE_SPACE         # Don't record lines starting with space
        setopt HIST_VERIFY               # Show command before executing from history
        setopt SHARE_HISTORY             # Share history between sessions
        setopt HIST_REDUCE_BLANKS        # Remove blanks from commands
        
        # Interactive search with fzf (enhanced tab completion)
        export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'echo {}'"
        export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || ls -la {}'"
        export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
      '';
    };
  };
}
