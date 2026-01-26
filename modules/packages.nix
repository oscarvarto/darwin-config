{pkgs}:
with pkgs; [
  # Basic system packages
  cachix
  coreutils
  curl
  alejandra
  bashInteractive
  bash-completion
  killall
  openssh
  sqlite
  wget
  zip
  btop
  jujutsu
  pixi # Python environment management (conda-forge + PyPI)

  ## Text and terminal utilities
  fd
  # marksman # Disabled - dotnet pulls in Swift which fails to build. Use: brew install marksman
  # GitHub CLI and extensions
  gh
  github-copilot-cli
  gh-dash
  gh-i
  gh-markdown-preview
  gh-notify
  gh-poi
  gh-s
  gh2md

  htop
  iftop

  # Jira
  # super-productivity # nix build broken (use homebrew package instead)
  jira-cli-go
  # jiratui

  jq
  mdq
  krunkit
  lazyjj
  lua51Packages.lua
  lua51Packages.luarocks
  (ripgrep.override {withPCRE2 = true;})
  mermaid-cli
  # mermaid-filter removed - Linux-only (depends on Chromium which doesn't support Darwin)
  # Use mermaid-cli directly for diagram generation if needed
  nurl
  pandoc
  pandoc-acro
  pandoc-eqnos
  pandoc-fignos
  pandoc-secnos
  pandoc-tablenos
  pandoc-imagine
  pandoc-include
  pandoc-lua-filters
  haskellPackages.pdftotext
  podman-tui
  tree
  unrar
  unzip

  # Nix development tools
  nix-prefetch-github
  statix

  # Table-like output tools (nushell-like experience)
  procs # Modern replacement for ps with table output
  dust # Intuitive disk usage with tree view
  bandwhich # Network utilization by process, connection, etc.
  bottom # System monitor with table views (aliased as btm)
  gping # Ping with graph
  hexyl # Hex viewer with colored output
  tokei # Code statistics in table format
  hyperfine # Command-line benchmarking tool with tables
  sd # Better sed with intuitive syntax
  delta # Better git diff viewer
  zoxide # Smarter cd with frecency tracking
  # Tools like cmake/pkg-config are no longer required for runtime
  # vterm compilation since vterm is prebuilt via Nix. Keep your
  # environment lean; add them back only if needed elsewhere.

  # matrix-hookshot
  neo # lol

  # Encryption and security tools
  age
  bfg-repo-cleaner
  gnupg
  libfido2

  # Cloud-related tools and SDKs
  docker
  docker-compose

  # Media-related packages
  ffmpeg

  # JVM (Java, Clojure, ...)
  jdk25

  # Node.js development tools
  nodejs

  # Spell checking
  (aspellWithDicts (dicts: with dicts; [en en-computers en-science es]))
  enchant
  isync

  # Font packages
  font-awesome

  # Python environment is now managed via pixi (see python-env/pixi.toml)
  # Run `pixi install` in python-env/ to set up the environment

  # Python package management
  uv # Fast Python package installer and dependency resolver

  # Darwin-specific packages
  # awscli2 # AWS CLI v2 with SSO support - temporarily disabled due to long build time
  # dockutil # Disabled - Swift 5.10.1 build fails on nixpkgs-unstable, use Homebrew instead: brew install dockutil
  mas

  # Shell completion tools
  fish # Required for Nushell's fish completer (fixed via overlay)
  nushell
  # xonsh is provided by pixi environment (see python-env/pixi.toml)
  carapace
  carapace-bridge
  zellij

  # Zsh plugins for enhanced shell experience
  zsh-autosuggestions
  zsh-syntax-highlighting
]
