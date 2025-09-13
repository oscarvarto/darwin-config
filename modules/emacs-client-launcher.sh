#!/usr/bin/env bash
# Emacs Client Launcher for Dock
# This script is used to launch emacsclient when clicking the Emacs icon in the Dock

# Check if emacsclient can connect to the server
if /Users/oscarvarto/.nix-profile/bin/emacsclient -e "(emacs-version)" >/dev/null 2>&1; then
    # Server is running, open a new frame
    exec /Users/oscarvarto/.nix-profile/bin/emacsclient -nc "$@"
else
    # Server is not running, which shouldn't happen with home-manager service
    # But as a fallback, try to start it
    echo "Emacs daemon not running. This shouldn't happen with home-manager service." >&2
    # The service should auto-restart, so just try again after a moment
    sleep 1
    exec /Users/oscarvarto/.nix-profile/bin/emacsclient -nc "$@"
fi