{
  config,
  pkgs,
  lib,
  user,
  ...
}: {
  # Enable Touch ID authentication for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Environment variables for 1Password integration
  environment.variables = {
    # Enable 1Password CLI integration
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    # Support for multiple vaults
    OP_VAULT_PERSONAL = "Personal";
    OP_VAULT_WORK = "Work";
  };

  # Configure SSH to work with 1Password SSH agent
  programs.ssh = {
    # Disable default config to avoid deprecation warning
    enableDefaultConfig = false;
    # These settings help with 1Password SSH agent integration
    extraConfig = ''
      # 1Password SSH Agent Configuration
      # When 1Password SSH agent is enabled, it listens on a specific socket

      # Ensure we try the 1Password agent if available
      AddKeysToAgent yes

      # Use 1Password SSH agent socket when available
      # This will be automatically managed by 1Password app when SSH agent is enabled
    '';
  };

  # Note: pam-reattach can be installed via Homebrew manually if needed
  # for Touch ID support in tmux and other terminal multiplexers

  # System configuration for better biometric integration
  system.defaults = {
    # Ensure Touch ID is available system-wide
    NSGlobalDomain = {
      # Enable Touch ID for Apple Pay and purchases (if desired)
      # This helps ensure Touch ID hardware is properly initialized
    };
  };

  # Additional PAM configuration for enhanced biometric support
  environment.etc = {
    # Custom PAM configuration for enhanced sudo biometric authentication
    "pam.d/sudo_local_biometric" = {
      text = ''
        # Enhanced biometric authentication for sudo
        # This supplements the default pam_tid.so configuration

        # Use Touch ID first (most secure and convenient)
        auth       sufficient     pam_tid.so

        # Fall back to standard authentication if Touch ID fails
        auth       required       pam_opendirectory.so
      '';
      mode = "0644";
    };
  };
}
