{
  zellij-nix,
  zellijNightlyPackage,
  ...
}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    # Overlays to fix package issues
    overlays = [
      zellij-nix.inputs.rust-overlay.overlays.default
      zellij-nix.overlays.nightly
      (final: prev: {
        zellij = zellijNightlyPackage final;
      })
      (final: prev: {
        zellij-nightly = zellijNightlyPackage final;
        zellij-upstream-nightly = prev.zellij-upstream-nightly.overrideAttrs (oldAttrs: {
          buildInputs = (oldAttrs.buildInputs or []) ++ [final.zlib final.curl];
        });
      })

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
