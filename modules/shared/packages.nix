{ pkgs }:

with pkgs;
[
  coreutils
  curl
  alejandra
  bash-completion
  btop
  jujutsu
  killall
  neofetch
  openssh
  pixi
  sqlite
  wget
  zip

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
  fd
  font-awesome
  noto-fonts
  noto-fonts-emoji-blob-bin

  # JVM (Java, ...)

  # Node.js development tools
  nodejs

  # Text and terminal utilities
  (aspellWithDicts (dicts: with dicts; [ en en-computers en-science es]))
  enchant
  htop
  iftop
  jetbrains-mono
  jq
  (ripgrep.override {withPCRE2 = true;})
  isync
  nurl
  tree
  unrar
  unzip

  qt6.full
  # Python packages
  (python3.withPackages (python-pkgs: with python-pkgs; [
    debugpy
    pandas
    requests
    sexpdata tld
    pyqt6 pyqt6-sip
    pyqt6-webengine epc lxml # for eaf
    pysocks # eaf-browser

    jupyterlab
    matplotlib
    polars
    python
    sympy
    uv
  ]))
]
