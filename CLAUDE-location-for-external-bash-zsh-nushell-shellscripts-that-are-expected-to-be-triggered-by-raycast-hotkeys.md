# Location for external bash/zsh//nushell shellscripts that are expected to be triggered by Raycast hotkeys

When nix creates an external script that will be triggered by a Raycast hotkey, put them at ~/.local/share/bin

This rule does not apply to other kinds of files like plist files, that are expected to be in the macOS standard
directories. For all the plist files created by nix, create them at the user level, so that there are not problems with
SIP (System Integrity Protection).
