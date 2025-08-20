{ ... }:

{

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays =
      # Apply each overlay found in the /overlays directory
      let path = ../../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
          (filter (n: match ".*\\.nix" n != null ||
                      pathExists (path + ("/" + n + "/default.nix")))
                  (attrNames (readDir path)))
      ++ [
        # Override to fix apple_sdk compatibility issues
        (final: prev: {
          # Override packages that might still reference the old SDK
          python3 = prev.python3.override {
            packageOverrides = python-final: python-prev: {
              # Override any problematic Python packages here if needed
            };
          };
          
          # Override Qt packages to use newer SDK if needed
          qt6 = prev.qt6 // {
            qtbase = prev.qt6.qtbase;
            qtwebengine = prev.qt6.qtwebengine;
            qttools = prev.qt6.qttools;
          };
        })
      ];
  };
}
