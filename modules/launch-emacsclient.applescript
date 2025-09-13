#!/usr/bin/osascript
-- AppleScript to launch emacsclient
-- This can be saved as an Application using Script Editor or Automator

on run
    try
        -- Try to create a new Emacs frame using emacsclient
        do shell script "/Users/oscarvarto/.nix-profile/bin/emacsclient -nc &"
    on error
        -- If that fails, the daemon might not be running (shouldn't happen with home-manager)
        display notification "Starting Emacs..." with title "Emacs"
        delay 1
        do shell script "/Users/oscarvarto/.nix-profile/bin/emacsclient -nc &"
    end try
end run