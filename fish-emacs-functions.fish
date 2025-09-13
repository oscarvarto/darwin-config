# Fish Emacs functions
# Emacs daemon is now managed by home-manager service
# These functions use the default socket from the managed service

# Terminal Emacs function - uses default socket from managed service
function t
    # Launch emacsclient with zsh as SHELL for POSIX compatibility
    # Ensure Emacs can find ghostty terminfo
    if test "$TERM" = "xterm-ghostty"
        env SHELL=/bin/zsh TERMINFO=$HOME/.terminfo ~/.nix-profile/bin/emacsclient -nw $argv
    else
        env SHELL=/bin/zsh ~/.nix-profile/bin/emacsclient -nw $argv
    end
end

# GUI Emacs client function - uses default socket from managed service
function e
    # Launch emacsclient with zsh as SHELL for POSIX compatibility
    env SHELL=/bin/zsh ~/.nix-profile/bin/emacsclient -nc $argv
end
end
