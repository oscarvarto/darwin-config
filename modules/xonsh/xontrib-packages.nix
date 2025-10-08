{
  lib,
  pkgs,
}: let
  pythonPackages = pkgs.python3Packages;

  # Helper for setuptools-based xontribs fetched from PyPI.
  buildSetuptoolsXontrib = {
    pname,
    version,
    hash,
    url ? null,
    patches ? [],
    propagatedBuildInputs ? [],
    nativeBuildInputs ? [],
    description ? "",
    homepage ? "",
    license ? lib.licenses.mit,
    imports ? [],
    postPatch ? "",
    postInstall ? "",
  }:
    pythonPackages.buildPythonPackage (
      {
        inherit pname version propagatedBuildInputs nativeBuildInputs;
        format = "setuptools";
        src =
          if url != null
          then pkgs.fetchurl {inherit url hash;}
          else pkgs.fetchPypi {inherit pname version hash;};
        patches = patches;
        doCheck = false;
        pythonImportsCheck = imports;
        meta = {
          inherit description homepage license;
        };
      }
      // lib.optionalAttrs (postPatch != "") {inherit postPatch;}
      // lib.optionalAttrs (postInstall != "") {inherit postInstall;}
    );

  # Helper for pyproject/poetry based xontribs.
  buildPyprojectXontrib = {
    pname,
    version,
    hash,
    url ? null,
    patches ? [],
    propagatedBuildInputs ? [],
    buildSystem ? [],
    description ? "",
    homepage ? "",
    license ? lib.licenses.mit,
    imports ? [],
    postPatch ? "",
    postInstall ? "",
  }:
    pythonPackages.buildPythonPackage (
      {
        inherit pname version propagatedBuildInputs;
        format = "pyproject";
        nativeBuildInputs = buildSystem;
        src =
          if url != null
          then pkgs.fetchurl {inherit url hash;}
          else pkgs.fetchPypi {inherit pname version hash;};
        patches = patches;
        doCheck = false;
        pythonImportsCheck = imports;
        meta = {
          inherit description homepage license;
        };
      }
      // lib.optionalAttrs (postPatch != "") {inherit postPatch;}
      // lib.optionalAttrs (postInstall != "") {inherit postInstall;}
    );

  carapaceBin = let
    pname = "xontrib-carapace-bin";
    version = "0.1.0";
    generatedSrc = pkgs.runCommand "${pname}-${version}-src" {} ''
      mkdir -p $out/xontrib
      install -m 0644 ${./python/carapace_bin.py} $out/xontrib/carapace_bin.py
      install -m 0644 ${./python/carapace_setup.py} $out/setup.py
    '';
  in
    pythonPackages.buildPythonPackage {
      inherit pname version;
      format = "setuptools";
      src = generatedSrc;
      propagatedBuildInputs = [pythonPackages.xonsh];
      doCheck = false;
      pythonImportsCheck = [];
      meta = {
        description = "Lightweight xontrib that bootstraps carapace-bin completions";
        homepage = "https://carapace-sh.github.io/carapace-bin/";
        license = lib.licenses.mit;
      };
    };
in {
  # Map from logical xontrib name to packaged derivation.
  sh = buildSetuptoolsXontrib {
    pname = "xontrib-sh";
    version = "0.3.1";
    hash = "sha256-qIr/VKCdcSBrtz/4ttpxV2i/4D9t3hw1D0AuzGA9DMk=";
    url = "https://files.pythonhosted.org/packages/2d/1a/5f28e30d47e95d2e430d7fd45e55fe3884c027f2461b28ba0d85dc3a2ad2/xontrib_sh-0.3.1.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh];
    description = "Paste and run commands from other shells in xonsh";
    homepage = "https://github.com/anki-code/xontrib-sh";
    license = lib.licenses.bsd3;
  };
  argcomplete = buildSetuptoolsXontrib {
    pname = "xontrib-argcomplete";
    version = "0.3.4";
    hash = "sha256-mp1lLpGXah4YMTgHX1dX0IlPdSh4eOkKUvIbHbyRpFE=";
    url = "https://files.pythonhosted.org/packages/51/a4/f99338ec4b45be0547417cdc38e20a5c748bb5e10be8c88d0184d2d1f27b/xontrib_argcomplete-0.3.4.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh];
    description = "argcomplete support for xonsh";
    homepage = "https://github.com/anki-code/xontrib-argcomplete";
    license = lib.licenses.bsd3;
  };
  zoxide = buildPyprojectXontrib {
    pname = "xontrib-zoxide";
    version = "1.1.0";
    hash = "sha256-a2K7VbXTKW3pEWerRyeoPy1RCn3piu7MzgI6b2ZGSWY=";
    url = "https://files.pythonhosted.org/packages/ea/1e/3320dc7a83f7c9e4c919831dc0abddc19fa049420c3f796b14990a48856c/xontrib_zoxide-1.1.0.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh];
    buildSystem = [pythonPackages.poetry-core];
    postPatch = ''
      ${pythonPackages.python.interpreter} ${./python/zoxide_patch.py} xontrib/zoxide/zoxide.py
    '';
    description = "zoxide integration for xonsh";
    homepage = "https://github.com/dyuri/xontrib-zoxide";
  };
  starship = let
    pname = "xontrib-prompt-starship";
    version = "0.3.6";
    generatedSrc = pkgs.runCommand "${pname}-${version}-src" {} ''
      mkdir -p $out/xontrib
      install -m 0644 ${./python/prompt_starship.py} $out/xontrib/prompt_starship.py
      install -m 0644 ${./python/prompt_starship_setup.py} $out/setup.py
    '';
  in
    pythonPackages.buildPythonPackage {
      inherit pname version;
      format = "setuptools";
      src = generatedSrc;
      propagatedBuildInputs = [pythonPackages.xonsh];
      doCheck = false;
      pythonImportsCheck = [];
      meta = {
        description = "Starship prompt integration for xonsh with improved nix compatibility";
        homepage = "https://github.com/anki-code/xontrib-prompt-starship";
      };
    };
  kitty = buildSetuptoolsXontrib {
    pname = "xontrib-kitty";
    version = "0.0.2";
    hash = "sha256-MoAylQLdZd9TaKDe7nNYCN4vyqloAoHfCrBRKGPJyro=";
    url = "https://files.pythonhosted.org/packages/08/c8/e04ea718250905d10498514a60bd843ab803200bdd2de8d7b2cb0e4853d1/xontrib-kitty-0.0.2.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh];
    description = "Kitty terminal integration for xonsh";
    homepage = "https://github.com/scopatz/xontrib-kitty";
    license = lib.licenses.bsd2;
  };
  homebrew = buildPyprojectXontrib {
    pname = "xontrib-homebrew";
    version = "0.2.1";
    hash = "sha256-JKKdLE7Se++GrN702YqVJUsq0e/vrnA3rtKY8TcT8CA=";
    url = "https://files.pythonhosted.org/packages/ae/1f/cc27cd30bff964af80077b0a829fd0788fa6dcb1a02a71a34d3ff368ca0a/xontrib_homebrew-0.2.1.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh];
    buildSystem = [pythonPackages.poetry-core];
    description = "Expose Homebrew environment variables to xonsh";
    homepage = "https://github.com/eugenesvk/xontrib-homebrew";
  };
  "1password" = buildPyprojectXontrib {
    pname = "xontrib-1password";
    version = "0.3.2";
    hash = "sha256-/BcWicAUqUagpb7hC9f7sWiCslbBIMER+D6fL9au2fc=";
    url = "https://files.pythonhosted.org/packages/df/ee/6308a9474c0f391ce2b2f1c22c9b0c4bb9f10e80a11ad6b9c54177ebc93a/xontrib_1password-0.3.2.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh];
    buildSystem = [pythonPackages.poetry-core pythonPackages.tomli];
    description = "1Password CLI integration for xonsh";
    homepage = "https://github.com/drmikecrowe/xontrib-1password";
  };
  clp = buildPyprojectXontrib {
    pname = "xontrib-clp";
    version = "0.1.7";
    hash = "sha256-BZu0jMUQmG9/99O7Ipyz+LTjDgxucZ1Tbe3bk/WHWLs=";
    url = "https://files.pythonhosted.org/packages/c6/9f/2fa54574470141368adb7181c4b3cbb104551cf8b5213f776c9a6d634d5c/xontrib_clp-0.1.7.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh pythonPackages.pyperclip];
    buildSystem = [pythonPackages.setuptools pythonPackages.wheel];
    description = "Copy command output to the clipboard in xonsh";
    homepage = "https://github.com/anki-code/xontrib-clp";
  };
  pipeliner = buildSetuptoolsXontrib {
    pname = "xontrib-pipeliner";
    version = "0.5.0";
    hash = "sha256-nFuUATgLie2K5L9W7K7rwuWyfatCR2EojGP90cVZwHE=";
    url = "https://files.pythonhosted.org/packages/e1/ee/3fd8c29c384a261f2c6204dbc06a24aee471b9b7bc61c2873164050782ea/xontrib_pipeliner-0.5.0.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh pythonPackages.six];
    description = "Process command pipelines with inline Python";
    homepage = "https://github.com/anki-code/xontrib-pipeliner";
    license = lib.licenses.bsd3;
  };
  cheatsheet = buildSetuptoolsXontrib {
    pname = "xontrib-cheatsheet";
    version = "0.4.4";
    hash = "sha256-gSjzw3aElsCNEtULaGFKFGtalZeGya/mkNQkrjR7r7Y=";
    url = "https://files.pythonhosted.org/packages/33/8d/897c20666a57731892eb7b63215dbc10d6a022effe0a36041ee717ecb5f0/xontrib-cheatsheet-0.4.4.tar.gz";
    propagatedBuildInputs = [pythonPackages.xonsh];
    description = "Cheatsheet with copy-pastable xonsh examples";
    homepage = "https://github.com/anki-code/xontrib-cheatsheet";
  };
  "carapace-bin" = carapaceBin;
}
