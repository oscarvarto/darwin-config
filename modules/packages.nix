{
  pkgs,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
  pythonWorkspace,
}: let
  lib = pkgs.lib;
  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = pythonWorkspace;
  };

  stdenvForPython = pkgs.stdenv.override {
    targetPlatform =
      pkgs.stdenv.targetPlatform
      // {darwinSdkVersion = "26.0.1";};
  };

  python = pkgs.python3.override {
    stdenv = stdenvForPython;
  };

  pythonPackagesBase = pkgs.callPackage pyproject-nix.build.packages {inherit python;};

  pyprojectOverlay = workspace.mkPyprojectOverlay {sourcePreference = "wheel";};

  pythonSet = pythonPackagesBase.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      pyprojectOverlay
      (final: prev: {
        # Use prebuilt packages from nixpkgs for problematic packages
        # that have build dependencies missing in uv2nix resolution
        docopt = pkgs.python3Packages.docopt;
        epc = pkgs.python3Packages.epc;
        "path-and-address" = pkgs.python3Packages.path-and-address;
        scipy = pkgs.python3Packages.scipy;
      })
    ]
  );

  # Production-ready uv2nix dependency specification
  # This configuration provides the core benefit: fast builds for heavy packages
  # while working around current uv2nix limitations for problematic packages

  # Format: { package-name = [ extras ]; }
  # Note: package names are normalized to lowercase in uv2nix
  coreDeps = {
    # Essential Python utilities - these get prebuilt wheels via uv2nix
    beautifulsoup4 = [];
    requests = [];
    pygments = [];
    pillow = [];
    prompt-toolkit = []; # Required for Atuin xonsh support

    # Python development basics
    pip = [];
    setuptools = [];
    wheel = [];
    debugpy = [];

    # Include xonsh packages to ensure they use Python 3 from uv2nix
    # instead of falling back to nixpkgs which might pull Python 2
    xonsh = [];
    xontrib-argcomplete = [];
    xontrib-cheatsheet = [];
    xontrib-clp = [];
    xontrib-homebrew = [];
    xontrib-pipeliner = [];
    xontrib-sh = [];
    xontrib-zoxide = [];
  };

  pythonEnvBase = pythonSet.mkVirtualEnv "darwin-config-env" coreDeps;

  pythonVersion = pythonPackagesBase.python.pythonVersion;
  sitePackagesPath = "lib/python${pythonVersion}/site-packages";

  pythonEnv = pkgs.runCommand "darwin-config-env" {} ''
    mkdir -p "$out"
    cp -a ${pythonEnvBase}/. "$out/"
    chmod -R u+w "$out"

    # Install local xontribs
    install -Dm644 ${./xonsh/python/prompt_starship.py} "$out/${sitePackagesPath}/xontrib/prompt_starship.py"
    install -Dm644 ${./xonsh/python/carapace_bin.py} "$out/${sitePackagesPath}/xontrib/carapace_bin.py"
    install -Dm644 ${./xonsh/python/carapace_setup.py} "$out/${sitePackagesPath}/xontrib/carapace_setup.py"

    # Create placeholder xontribs for missing integrations
    # (these can be expanded later with actual implementations)
    mkdir -p "$out/${sitePackagesPath}/xontrib"

    # Create minimal kitty xontrib
    cat > "$out/${sitePackagesPath}/xontrib/kitty.py" << 'EOF'
"""Minimal kitty terminal integration for xonsh."""
# Placeholder - kitty integration can be expanded
pass
EOF

    # Create minimal 1password xontrib
    cat > "$out/${sitePackagesPath}/xontrib/1password.py" << 'EOF'
"""Minimal 1Password CLI integration for xonsh."""
# Placeholder - 1Password integration can be expanded
pass
EOF
  '';
in
  with pkgs; [
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
    pixi

    # Text and terminal utilities
    fd
    htop
    iftop
    jq
    lazyjj
    (ripgrep.override {withPCRE2 = true;})
    nurl
    tree
    unrar
    unzip

    # Nix development tools
    nix-prefetch-github # For emacs pinning system

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
    (aspellWithDicts (dicts: with dicts; [en en-computers en-science es]))
    enchant
    isync

    # Font packages
    font-awesome

    # Python environment managed via uv2nix (includes PyQt6 / xontrib tooling)
    pythonEnv

    # Python package management
    uv # Fast Python package installer and dependency resolver

    # Darwin-specific packages
    # awscli2 # AWS CLI v2 with SSO support - temporarily disabled due to long build time
    dockutil
    mas

    # Shell completion tools
    fish # Required for Nushell's fish completer
    nushell
    carapace
    zellij

    # Zsh plugins for enhanced shell experience
    zsh-autosuggestions
    zsh-syntax-highlighting

    # super-productivity
  ]
