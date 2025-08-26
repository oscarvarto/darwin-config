# Fish Emacs functions - equivalent to nushell implementation
# These provide the same functionality as the scripts in ~/.local/share/bin/

# Find doom socket file in TMPDIR
function doom-socket
    set -l tmpdir $TMPDIR
    if test -z "$tmpdir"
        set tmpdir "/tmp"
    end
    
    # Use find instead of fd for better compatibility
    set -l socket_file (find "$tmpdir" -name "doom*" -type s 2>/dev/null | head -n1)
    
    if test -z "$socket_file"
        return 1
    end
    
    # Test if the socket is actually active by trying to connect
    if /opt/homebrew/bin/emacsclient -s "$socket_file" --eval "t" >/dev/null 2>&1
        echo "$socket_file"
    else
        # Socket file exists but is stale, remove it
        rm -f "$socket_file"
        return 1
    end
end

# Helper function to ensure daemon is running and return socket path
function ensure-emacs-daemon
    set -l socket_path (doom-socket)
    
    if test -z "$socket_path"
        echo "Emacs daemon socket not found. Starting Emacs daemon first with: emacs --daemon=doom" >&2
        
        # Start Emacs daemon with zsh as SHELL for POSIX compatibility
        env SHELL=/bin/zsh emacs --daemon=doom
        
        # Wait for daemon to start and create socket
        set -l retries 0
        while test -z "$socket_path" -a $retries -lt 18
            sleep 0.5
            set socket_path (doom-socket)
            set retries (math $retries + 1)
        end
        
        if test -z "$socket_path"
            echo "Failed to start Emacs daemon or find socket after 9 seconds" >&2
            return 1
        end
    end
    
    echo "$socket_path"
end