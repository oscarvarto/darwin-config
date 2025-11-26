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
      "jetbrains/utils"
      "oscarvarto/jank"
    ];

    brews = [
      "7-zip"
      "angular-cli"
      "aria2"
      "atuin"
      "autoconf"
      "autoconf-archive"
      "automake"
      "awscli"
      "bat"
      "bat-extras"
      "bazelisk"
      "bfg"
      "boot-clj"
      "boost"
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
      "entr"
      "double-conversion"
      "eza"
      "fernflower"
      "ffmpeg"
      "fontforge"
      "foreman"
      "gcc"
      "gemini-cli"
      "gh"
      "git-lfs"
      "git-filter-repo"
      "glab"
      "gnu-tar"
      "go"
      "gradle"
      "grep"
      "helix"
      "hugo"
      "imagemagick"
      "jq"
      "kotlin-lsp"
      "libedit"
      "libgccjit"
      "libsql"
      "libtool"
      {
        name = "llvm";
        args = ["HEAD"];
      }
      "oscarvarto/jank/jank-git"
      "libvterm"
      "livekit"
      "markdown-oxide"
      "markdownlint-cli2"
      # marksman moved to Nix packages to avoid dotnet formula conflict with dotnet-sdk cask
      # "marksman"
      "maven"
      "minio"
      "mosh"
      "mysql@8.4"
      "multimarkdown"
      "nasm"
      "ncurses"
      "neo4j"
      "ninja"
      "ollama"
      "podman"
      "podman-tui"
      "pueue"
      "pass"
      "pkg-config"
      "pinentry-mac"
      "poppler"
      "postgresql@15"
      "prettier"
      "resvg"
      "sbcl"
      "sdl2"
      "sdl2_image"
      "sdl2_ttf"
      "stow"
      "swig"
      "trash-cli"
      "tree-sitter"
      "tree-sitter-cli"
      "vim"
      "vivid"
      "vcpkg"
      "volta"
      "wmctrl"
      "xz" # lzma is part of xz
      "xcode-build-server"
      "yq"
      "zig"
      "zip"
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

    # masApps = {
    #   "1Password for Safari" = 1569813296;
    #   "Amazon Prime Video" = 545519333;
    #   "Okta Verify" = 490179405;
    #   "Okta Extension App" = 1439967473;
    #   "rcmd" = 1596283165;
    #   "Xcode" = 497799835;
    # };
  };
}
