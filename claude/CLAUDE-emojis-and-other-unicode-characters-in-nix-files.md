# Emojis and other unicode characters in nix files.

When there's a need to use/embed unicode or emojis in my nix configuration files, make sure to correctly encode them
with escaped ASCII strings using the \UXXXX format. When creating an embedded bash script in nix, consider correct
escaping that works for bash, in the context of an embedded nix script.
