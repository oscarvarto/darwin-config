{ config, pkgs, lib, user ? "oscarvarto", ... }:

{
  # Git pre-commit hook (nushell version)
  home.file.".config/git/hooks/pre-commit" = {
    executable = true;
    source = ./scripts/nu/git-pre-commit-secrets.nu;
  };

  # Nushell scripts for git security and utilities
  # Following stow rule: scripts should be in .local/share/bin
  home.file.".local/share/bin/git-pre-commit-secrets" = {
    executable = true;
    source = ./scripts/nu/git-pre-commit-secrets.nu;
  };

  home.file.".local/share/bin/git-1p-helper" = {
    executable = true;
    source = ./scripts/nu/git-1p-helper.nu;
  };

  home.file.".local/share/bin/update-work-git-config" = {
    executable = true;
    source = ./scripts/nu/update-work-git-config.nu;
  };

  home.file.".local/share/bin/git-bfg-cleaner" = {
    executable = true;
    source = ./scripts/nu/git-bfg-cleaner.nu;
  };
}
