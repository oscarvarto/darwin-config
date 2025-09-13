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
    ];

    brews = [
      "7-zip"
      "angular-cli"
      "aria2"
      "autoconf"
      "autoconf-archive"
      "automake"
      "bat"
      "bat-extras"
      "bfg"
      "carapace"
      "cargo-binstall"
      "ccache"
      "cmake"
      "cmake-language-server"
      "coursier"
      "difftastic"
      "eza"
      "ffmpeg"
      "fontforge"
      "gemini-cli"
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
      "markdownlint-cli2"
      "marksman"
      "maven"
      "mosh"
      "mysql@8.4"
      "multimarkdown"
      "nasm"
      "ncurses"
      "neo4j"
      "ninja"
      "pandoc"
      "pueue"
      "pass"
      "pkg-config"
      "pinentry-mac"
      "poppler"
      "prettier"
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
    # This message is safe to ignore. (https://github.com/dustinlyons/darwin-config/issues/83)

    masApps = {
      "1Password for Safari" = 1569813296;
      "neptunes" = 1006739057;
      "Okta Verify" = 490179405;
      "Okta Extension App" = 1439967473;
      "rcmd" = 1596283165;
      # "XCode" = 497799835;
    };
  };
}
