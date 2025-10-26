{
  config,
  pkgs,
  lib,
  ...
}: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
      extraFlags = ["--verbose"];
      upgrade = true;
    };

    taps = [
      "borkdude/brew"
      "oscarvarto/jank"
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
      "boot-clj"
      "borkdude/brew/babashka"
      # Moved to Nix packages to avoid conflicts with xonsh xontrib
      # "carapace"
      "cargo-binstall"
      "ccache"
      "cljfmt"
      "clojure"
      "clojure-lsp"
      "cmake"
      "cmake-language-server"
      "difftastic"
      "zip"
      "entr"
      "double-conversion"
      "eza"
      "ffmpeg"
      "fontforge"
      "gcc"
      "gemini-cli"
      "git-lfs"
      "gradle"
      "git-filter-repo"
      "gnu-tar"
      "go"
      "helix"
      "hugo"
      "imagemagick"
      # "oscarvarto/jank/jank-git"
      "jq"
      "libedit"
      "libsql"
      "libtool"
      "libgccjit"
      # {
      #   name = "llvm";
      #   args = ["HEAD"];
      # }
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
      "ollama"
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
      "tree-sitter"
      "tree-sitter-cli"
      "vivid"
      "vcpkg"
      "volta"
      "wmctrl"
      "xz" # lzma is part of xz
      "xcode-build-server"
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
      "Amazon Prime Video" = 545519333;
      "neptunes" = 1006739057;
      "Okta Verify" = 490179405;
      "Okta Extension App" = 1439967473;
      "rcmd" = 1596283165;
      "Xcode" = 497799835;
    };
  };
}
