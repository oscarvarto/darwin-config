{ config, pkgs, lib, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
      extraFlags = [ "--verbose" ];
      upgrade = true;
    };

    taps = [
      "d12frosted/homebrew-emacs-plus"
    ];

    brews = [
      "7-zip"
      "angular-cli"
      "aria2"
      "autoconf"
      "autoconf-archive"
      "automake"
      "awscli"
      "bat"
      "bat-extras"
      "bfg"
      "carapace"
      "cargo-binstall"
      "ccache"
      "cmake"
      "cmake-language-server"
      "difftastic"
      {
        name = "emacs-plus@31";
        args = [ "with-xwidgets" "with-imagemagick" "with-savchenkovaleriy-big-sur-curvy-3d-icon" "with-mailutils" ];
        link = true;
      }
      "eza"
      "ffmpeg"
      "gradle"
      "git-filter-repo"
      "go"
      "helix"
      "hugo"
      "imagemagick"
      "jq"
      "libedit"
      "libvterm"
      "libsql"
      "libtool"
      "llvm"
      "lua"
      "markdown-oxide"
      "marksman"
      "maven"
      "mosh"
      "mysql@8.4"
      "nasm"
      "ncurses"
      "ninja"
      "pandoc"
      "pueue"
      "pass"
      "pkg-config"
      "pinentry-mac"
      "poppler"
      "resvg"
      "stow"
      "swig"
      "trash-cli"
      "vivid"
      "vcpkg"
      "volta"
      "wmctrl"
      "xz" # lzma is part of xz
      "yq"
      "zellij"
      "zig"
    ];

    casks = pkgs.callPackage ./casks.nix {};
    caskArgs.appdir = "/Applications";

    # onActivation.cleanup = "uninstall";

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)

    masApps = {
      "1Password for Safari" = 1569813296;
      "neptunes" = 1006739057;
      "rcmd" = 1596283165;
      "XCode" = 497799835;
    };
  };
}
