{ ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };
    
    # No overlays from directory - any needed overlays are defined inline in system.nix
    overlays = [];
  };
}
