{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  # Minimal darwin-specific packages only
  awscli2  # AWS CLI v2 with SSO support
  dockutil
  mas
  netcoredbg
]
