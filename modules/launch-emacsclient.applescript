#!/usr/bin/osascript
-- AppleScript to launch emacsclient
-- This can be saved as an Application using Script Editor or Automator

on run
    try
        -- Try to create a new Emacs frame using emacsclient
        do shell script "/opt/homebrew/bin/emacsclient -nc &"
    on error
        -- If that fails, the daemon might not be running
        -- Start it manually with: emacs --daemon
        display notification "Emacs daemon not running. Start with: emacs --daemon" with title "Emacs"
    end try
end run