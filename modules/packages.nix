{ pkgs }:

with pkgs;
[
  # Basic system packages
  coreutils
  curl
  alejandra
  bash-completion
  killall
  openssh
  sqlite
  wget
  zip
  btop
  jujutsu
  lazyjj
  pixi

  # Text and terminal utilities
  htop
  iftop
  jq
  (ripgrep.override {withPCRE2 = true;})
  nurl
  tree
  unrar
  unzip
  fd
  
  # Table-like output tools (nushell-like experience)
  procs        # Modern replacement for ps with table output
  dust         # Intuitive disk usage with tree view
  bandwhich    # Network utilization by process, connection, etc.
  bottom       # System monitor with table views (aliased as btm)
  gping        # Ping with graph
  hexyl        # Hex viewer with colored output
  tokei        # Code statistics in table format
  hyperfine    # Command-line benchmarking tool with tables
  sd           # Better sed with intuitive syntax
  bat          # Better cat with syntax highlighting
  delta        # Better git diff viewer
  zoxide       # Smarter cd with frecency tracking

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

  # JVM (Java, ...)

  # Node.js development tools
  nodejs

  # Spell checking
  (aspellWithDicts (dicts: with dicts; [ en en-computers en-science es]))
  enchant
  isync

  # Qt6 packages
  qt6.full
  
  # Font packages
  jetbrains-mono
  font-awesome
  
  # Python packages with GUI dependencies
  (python3.withPackages (python-pkgs: with python-pkgs; [
    debugpy
    pandas
    requests
    sexpdata
    tld
    epc
    pysocks
    polars
    sympy
    uv
    # GUI-related packages
    grip
    pyqt6
    pyqt6-webengine
    matplotlib
    scipy
    numpy
  ]))
  
  # Darwin-specific packages
  awscli2  # AWS CLI v2 with SSO support
  dockutil
  mas
  netcoredbg

  # Shell completion tools
  fish  # Required for Nushell's fish completer
  nushell
  carapace
  
  # Zsh plugins for enhanced shell experience
  zsh-autosuggestions
  zsh-syntax-highlighting
]
