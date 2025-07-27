{ pkgs }:

with pkgs;
[
  coreutils
  curl
  alejandra
  aspell
  aspellDicts.en
  bash-completion
  btop
  jujutsu
  killall
  neofetch
  nil
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
  htop
  hunspell
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
    jupyterlab
    matplotlib
    polars
    pyqt6
    pysocks
    python
    sympy
    uv
  ]))
]
