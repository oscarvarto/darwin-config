{
  config,
  pkgs,
  lib,
  user ? "oscarvarto",
  pathConfig ? null,
  darwinConfigPath,
  ...
}: let
  nixDaemonInit = ''
    # Nix daemon setup
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
    fi
  '';

  # Secrets loader for bash/zsh (parses LazyVim secrets.lua)
  # Uses awk for portable parsing that works in both bash and zsh
  secretsFile = "${darwinConfigPath}/stow/lazyvim/.config/nvim/secrets.lua";
  secretsLoader = ''
    # Load API keys from LazyVim secrets.lua (not tracked in git)
    if [[ -f "${secretsFile}" ]]; then
      eval "$(${pkgs.gawk}/bin/awk '
        /^[[:space:]]*[A-Z_][A-Z0-9_]*[[:space:]]*=[[:space:]]*["\x27]/ {
          gsub(/^[[:space:]]+/, "")
          gsub(/,[[:space:]]*$/, "")
          split($0, parts, /[[:space:]]*=[[:space:]]*/)
          key = parts[1]
          value = $0
          sub(/^[^=]*=[[:space:]]*["\x27]/, "", value)
          sub(/["\x27][[:space:]]*$/, "", value)
          print "export " key "=\"" value "\""
        }
      ' "${secretsFile}")"
    fi
  '';

  sharedShellInit = ''
    # Fix for macOS libcrypto "poisoning" - ensures Nix's OpenSSL is loaded
    # instead of the system's abort()-ing stub (see: https://github.com/NixOS/nixpkgs/issues/160258)
    export DYLD_LIBRARY_PATH="${pkgs.openssl.out}/lib''${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"

    export LC_ALL="en_US.UTF-8"

    ${secretsLoader}

    # Set Xcode developer directory to release version
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

    # Force homebrew to use gcc-15 for emacs-plus@31 compatibility on macOS 26
    # export HOMEBREW_CC="gcc-15"
    # export HOMEBREW_CXX="g++-15"
    export HOMEBREW_VERBOSE=1

    # SDK path configuration for gcc-15 to find macOS frameworks and headers
    export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
    export MACOSX_DEPLOYMENT_TARGET="26.2"
    # Add framework search paths for gcc-15
    # export CPPFLAGS="-isysroot $SDKROOT -I$SDKROOT/usr/include -F$SDKROOT/System/Library/Frameworks"
    # export LDFLAGS="-isysroot $SDKROOT -L$SDKROOT/usr/lib -F$SDKROOT/System/Library/Frameworks"

    # LIBRARY_PATH for gcc-15 libgccjit compatibility (fixes "ld: library not found" errors)
    # Based on https://github.com/d12frosted/homebrew-emacs-plus/issues/554#issuecomment-1564287827
    # export LIBRARY_PATH="/opt/homebrew/opt/gcc/lib/gcc/15:/opt/homebrew/opt/libgccjit/lib/gcc/15:/opt/homebrew/opt/gcc/lib/gcc/15/gcc/aarch64-apple-darwin25/15"

    # jank wrapper function to clear Nix SDK variables
    # Fixes macOS 26 SDK header ordering issue (jank-lang/jank#560)
    jank() {
        local SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
        local DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

        # Clear Nix-provided compiler flags that interfere with jank's PCH compilation
        unset NIX_CFLAGS_COMPILE
        unset NIX_LDFLAGS
        unset NIX_APPLE_SDK_VERSION

        # Run jank with clean SDK environment
        env SDKROOT="$SDKROOT" DEVELOPER_DIR="$DEVELOPER_DIR" /opt/homebrew/bin/jank "$@"
    }

    # Define variables for directories
    export EMACSDIR=$HOME/.emacs.d

    # PATH is centrally managed in modules/path-config.nix for all shells
    # Do not edit PATH here; zsh uses envExtra/initExtra from zsh-darwin.nix

    # Remove history data we don't want to see
    export HISTIGNORE="pwd:ls:cd"

    # Ripgrep helper
    search() {
        rg -p --glob '!node_modules/*' "$@"
    }

    # Prevent emacsclient from auto-starting its own daemon
    # Start Emacs daemon manually with: emacs --daemon
    export ALTERNATE_EDITOR="false"
    export EDITOR="nvim"
    export VISUAL="code-insiders -w"
    export DARWIN_CONFIG_PATH="${darwinConfigPath}"

    # Load theme from cache file set by catppuccin theme switcher
    if [[ -f ~/.cache/zsh_theme ]]; then
        export ZSH_THEME=$(cat ~/.cache/zsh_theme 2>/dev/null | tr -d '\n')
    else
        export ZSH_THEME="dark"
    fi

    # JIRA API token is available on-demand via get-jira-api-token command
    # To set it manually: export JIRA_API_TOKEN=$(get-jira-api-token work)
    # This avoids 1Password biometric prompts on every shell startup

    # Load Zellij theme config if available (like in nushell configuration)
    if [[ -f ~/.cache/zellij_theme_config ]]; then
        source ~/.cache/zellij_theme_config
    fi

    # Ghostty terminal compatibility fallback (merged from terminal-support.nix)
    if [[ "$TERM" == "xterm-ghostty" ]] && ! command -v infocmp >/dev/null 2>&1; then
      export TERM="xterm-256color"
    elif [[ "$TERM" == "xterm-ghostty" ]] && ! infocmp xterm-ghostty >/dev/null 2>&1; then
      export TERM="xterm-256color"
    fi

    # Use existing helper scripts for Emacs; avoid duplicating logic here
    alias t="$HOME/.local/share/bin/t"
    alias e="$HOME/.local/share/bin/e"
    alias tt="$HOME/.local/share/bin/tt"
    alias edd="$HOME/.local/share/bin/edd"
    alias et="$HOME/.local/share/bin/et"
    alias ke="$HOME/.local/share/bin/ke"

    # nix shortcuts
    shell() {
        nix-shell '<nixpkgs>' -A "$1"
    }

    # Pixi environment with graph-tool (conda-forge + PyPI)
    # Usage: pixi-gt shell, pixi-gt run python, etc.
    pixi-gt() {
        local cmd="$1"
        shift
        pixi "$cmd" --manifest-path ~/darwin-config/python-env/pixi.toml "$@"
    }

    # Source shell functions from external file
    if [[ -f "$DARWIN_CONFIG_PATH/modules/shell-functions.sh" ]]; then
        source "$DARWIN_CONFIG_PATH/modules/shell-functions.sh"
    fi

    # Table-like output commands (similar to nushell)
    # Using eza for better ls output with icons and colors
    alias lls='eza --icons --group-directories-first'
    alias ll='eza --icons --group-directories-first -la --grid --header --git'
    alias ltt='eza --icons --group-directories-first -la --tree --level=2'
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
    alias catn='bat --style=numbers'
    alias catf='bat --style=full'

    # Code statistics
    alias loc='tokei'
    alias locs='tokei --sort lines'

    # Hex viewer
    alias hex='hexyl'

    # Better grep with ripgrep
    alias grepi='rg -i'
    alias grepl='rg -l'

    # Benchmarking
    alias bench='hyperfine'

    # String replacement
    alias replace='sd'

    # Function for JSON viewing with jq and bat
    jqc() {
        jq -C "$@" | bat --style=plain --language=json
    }

    alias tg="$EDITOR $HOME/.config/ghostty/config"
    # Emacs daemon is now managed by home-manager service
    # No need for manual daemon management
    alias pke="pkill -9 Emacs"
    alias gd="ghostty +show-config --default --docs"
    alias gp="git fetch --all -p; git pull; git submodule update --recursive"
    alias diff="difft"
    # Quick access to xonsh shell via pixi environment
    alias xsh='pixi run --manifest-path ~/darwin-config/python-env/pixi.toml xonsh'
    nb() {
        local verbose=false
        if [[ "$1" == "-v" ]]; then
            verbose=true
            shift
        fi

        pushd "$DARWIN_CONFIG_PATH" > /dev/null

        if $verbose; then
            nix run .#build -- --verbose "$@"
        else
            nix run .#build -- "$@"
        fi

        popd > /dev/null
    }

    ns() {
        local verbose=false
        if [[ "$1" == "-v" ]]; then
            verbose=true
            shift
        fi

        if $verbose; then
            ns-ghostty-safe -v "$@"
        else
            ns-ghostty-safe "$@"
        fi
    }

    alias avante='nvim -c "lua vim.defer_fn(function()require(\"avante.api\").zen_mode()end, 100)"'

    # Interactive search with fzf (enhanced tab completion)
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'echo {}'"
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || ls -la {}'"
    export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
  '';

  atuinInit = shell: ''
    # Initialize atuin for shell history sync
    if command -v atuin &> /dev/null; then
      eval "$(atuin init ${shell})"
    fi
  '';
in {
  programs = {
    # Shared shell utilities
    broot = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    # direnv is now managed directly in home-manager.nix to avoid conflicts

    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };

    # Consolidated zsh configuration for macOS
    zsh = {
      enable = true;
      autocd = false;
      cdpath = ["~/.local/share/src"];
      plugins = [];

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
        ${nixDaemonInit}

        # Centralized PATH setup (pre-plugins)
        ${
          if pathConfig != null
          then pathConfig.zsh.pathSetup
          else "# Centralized PATH config not available"
        }

        # Load zsh plugins
        # Autosuggestions plugin for fish-like suggestions
        if [[ -f ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        fi

        # Syntax highlighting plugin for colored commands
        if [[ -f ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        fi

        ${sharedShellInit}

        alias nz="nvim ~/.zshrc"

        # Function to show directory contents automatically when changing directories
        chpwd() {
            eza --icons --group-directories-first -la --grid --header --git
        }

        # Basic navigation
        bindkey '^F' forward-char     # Ctrl+F forward one character
        bindkey '^B' backward-char    # Ctrl+B backward one character
        bindkey '^E' end-of-line      # Ctrl+E to end of line
        bindkey '^A' beginning-of-line # Ctrl+A to beginning of line
        bindkey "^[[3~" delete-char

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

        ${atuinInit "zsh"}

        # Override prompt for Claude Code terminal (which doesn't render truecolor properly)
        # This must run after starship init to override it
        if [[ -n "$CLAUDECODE" ]]; then
          # Use a simple prompt for Claude Code
          # Shows: username@hostname current_dir git_branch >
          autoload -Uz vcs_info
          precmd_vcs_info() { vcs_info }
          precmd_functions+=( precmd_vcs_info )
          setopt prompt_subst
          zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'
          zstyle ':vcs_info:*' enable git
          PROMPT='%F{green}%n%f@%F{blue}%m%f %F{cyan}%~%f$vcs_info_msg_0_ > '
        fi

        # YAZELIX START v4 - Yazelix managed configuration (do not modify this comment)
        # delete this whole section to re-generate the config, if needed
        if [[ -n "$IN_YAZELIX_SHELL" ]]; then
          source "$HOME/.config/yazelix/shells/zsh/yazelix_zsh_config.zsh"
        fi
        # yzx command - always available for launching/managing yazelix
        yzx() {
            nu -c "use ~/.config/yazelix/nushell/scripts/core/yazelix.nu *; yzx $*"
        }
        alias yzh='yzx launch --here'
        # YAZELIX END v4 - Yazelix managed configuration (do not modify this comment)

        if [[ -n "''${IN_YAZELIX_SHELL:-}" ]] && [[ -n "''${EDITOR:-}" ]]; then
          hx() {
            "$EDITOR" "$@"
          }
        fi

        # Final centralized PATH override (post-plugins)
        ${
          if pathConfig != null
          then pathConfig.zsh.pathOverride
          else "# Centralized PATH override not available"
        }
      '';
    };

    bash = {
      enable = true;
      enableCompletion = true;
      profileExtra = ''
        # Ensure login shells load the interactive configuration
        if [ -f "$HOME/.bashrc" ]; then
          . "$HOME/.bashrc"
        fi
      '';
      bashrcExtra = lib.mkAfter ''
        ${nixDaemonInit}

        # Centralized PATH setup (pre-plugins)
        ${
          if pathConfig != null && pathConfig ? bash
          then pathConfig.bash.pathSetup
          else "# Centralized PATH config not available"
        }

        ${sharedShellInit}

        # Bash-specific history and readline behavior
        shopt -s histappend
        shopt -s cmdhist
        shopt -s checkwinsize
        shopt -s autocd
        shopt -s globstar
        shopt -s checkjobs
        HISTCONTROL=ignoreboth
        HISTSIZE=50000
        HISTFILESIZE=50000

        # Auto-display directory contents when changing directories
        __darwin_config_prev_pwd="$PWD"
        __darwin_config_auto_ls() {
          if [[ "$PWD" != "''${__darwin_config_prev_pwd:-}" ]]; then
            __darwin_config_prev_pwd="$PWD"
            eza --icons --group-directories-first -la --grid --header --git
          fi
        }

        if [[ -n "$PROMPT_COMMAND" ]]; then
          PROMPT_COMMAND="__darwin_config_auto_ls;$PROMPT_COMMAND"
        else
          PROMPT_COMMAND="__darwin_config_auto_ls"
        fi

        # Utility helpers for wrapping commands safely in bash
        stripansi() {
            sed -r "s/\x1B\[[0-9;]*[A-Za-z]//g"
        }

        safe() {
            stdbuf -oL -eL script -q -c "$1" /dev/null
        }

        run() {
            timeout 20s bash -lc "$1" | stripansi
        }

        ${atuinInit "bash"}

        # YAZELIX START v4 - Yazelix managed configuration (do not modify this comment)
        # delete this whole section to re-generate the config, if needed
        if [ -n "$IN_YAZELIX_SHELL" ]; then
          source "$HOME/.config/yazelix/shells/bash/yazelix_bash_config.sh"
        fi
        # yzx command - always available for launching/managing yazelix
        yzx() {
            nu -c "use ~/.config/yazelix/nushell/scripts/core/yazelix.nu *; yzx $*"
        }
        alias yzh='yzx launch --here'
        # YAZELIX END v4 - Yazelix managed configuration (do not modify this comment)

        if [[ -n "''${IN_YAZELIX_SHELL:-}" ]] && [[ -n "''${EDITOR:-}" ]]; then
          hx() {
            "$EDITOR" "$@"
          }
        fi

        # Final centralized PATH override (post-integrations)
        ${
          if pathConfig != null && pathConfig ? bash
          then pathConfig.bash.pathOverride
          else "# Centralized PATH override not available"
        }
      '';
    };
  };
}
