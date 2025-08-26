# Fish interactive shell initialization
# Theme configuration, colors, and interactive features

# Load theme from cache file set by catppuccin theme switcher
if test -f ~/.cache/fish_theme
    set -gx FISH_THEME (cat ~/.cache/fish_theme 2>/dev/null | string trim)
else
    set -gx FISH_THEME "dark"
end

# Load Zellij theme override if available (matching other shell configs)
if test -f ~/.cache/zellij_theme_config
    source ~/.cache/zellij_theme_config
end

# Set LS_COLORS and BAT_THEME based on fish theme (consistent with catppuccin theme switching)
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
    set -g fish_color_normal "333333"                  # normal text - dark gray
    set -g fish_color_command "0066cc"                # commands - blue
    set -g fish_color_keyword "990099"                # keywords - purple
    set -g fish_color_quote "009900"                  # quoted text - green
    set -g fish_color_redirection "cc6600"            # redirections - orange
    set -g fish_color_end "cc0000"                    # command separators - red
    set -g fish_color_error "cc0000" --bold          # errors - bold red
    set -g fish_color_param "666666"                 # parameters - medium gray
    set -g fish_color_comment "999999"               # comments - light gray
    set -g fish_color_autosuggestion "cccccc"        # autosuggestions - very light gray
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
    set -g fish_color_autosuggestion "666666"      # autosuggestions - medium gray
end

# Claude Code integration - Shift+Enter key binding (matching zsh configuration)
bind -M insert \e\[13\;2u 'echo "# Claude Code: Submit prompt"'
bind -M default \e\[13\;2u 'echo "# Claude Code: Submit prompt"'

# History settings (equivalent to other shells)
set -g fish_history_max 50000

# Initialize Emacs helper functions
__fish_emacs_init