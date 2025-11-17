{...}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    # Overlays to fix package issues
    overlays = [
      # Fix fish build on Darwin by disabling tests (nixpkgs#461406)
      # The upstream fix in PR#461779 hasn't reached nixpkgs-unstable yet
      (final: prev: {
        fish = prev.fish.overrideAttrs (oldAttrs: {
          doCheck = false;
        });
      })

      # Fix mise build by disabling tests that fail due to lazy_lock poisoning
      (final: prev: {
        mise = prev.mise.overrideAttrs (oldAttrs: {
          # Disable tests that fail with "Once instance has previously been poisoned"
          # This is a known issue with parallel test execution in some Rust versions
          doCheck = false;
        });
      })
    ];
  };
}
