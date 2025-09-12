# Fish login shell initialization
# Environment variables and non-interactive setup

# Nix daemon initialization (equivalent to Nushell initialization)
if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    set -gx NIX_SSL_CERT_FILE '/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt'
    set -gx NIX_PROFILES '/nix/var/nix/profiles/default ~/.nix-profile'
    set -gx NIX_PATH 'nixpkgs=flake:nixpkgs'
    # Note: PATH is handled by centralized path configuration in fish-config.nix
end

# Environment variables (matching current setup in modules/home-manager.nix)
set -gx DOTNET_ROOT "/usr/local/share/dotnet"
set -gx EMACSDIR "~/.emacs.d"
set -gx DOOMDIR "~/.doom.d"
set -gx DOOMLOCALDIR "~/.emacs.d/.local"
set -gx CARGO_HOME "$HOME/.cargo"

# Set Xcode developer directory to release version (matching other shells)
set -gx DEVELOPER_DIR "/Applications/Xcode.app/Contents/Developer"

# Enchant/Aspell configuration (matching current setup)
set -gx ENCHANT_ORDERING 'en:aspell,es:aspell,*:aspell'

# Editor configuration
set -gx EDITOR "nvim"