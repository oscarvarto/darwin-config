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
  neofetch
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
    pyqt6
    matplotlib
    scipy
    numpy
  ]))
  
  # Darwin-specific packages
  awscli2  # AWS CLI v2 with SSO support
  dockutil
  mas
  netcoredbg
]
