# Example: Hybrid environment setup combining agenix + 1Password/pass
{ config, pkgs, user, ... }:

let
  # Script to set up environment variables from multiple sources
  setupEnvScript = pkgs.writeShellScript "setup-hybrid-env" ''
    #!/usr/bin/env bash
    
    # Export agenix-managed secrets as environment variables
    export OPENAI_API_KEY="$(cat ${config.age.secrets.openai-api-key.path} 2>/dev/null || echo "")"
    export ANTHROPIC_API_KEY="$(cat ${config.age.secrets.anthropic-api-key.path} 2>/dev/null || echo "")"
    export POSTGRES_PASSWORD="$(cat ${config.age.secrets.postgres-password.path} 2>/dev/null || echo "")"
    
    # Export 1Password/pass managed secrets
    if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
      # Use 1Password for runtime secrets
      export WORK_API_TOKEN="$(op item get work-api --fields token 2>/dev/null || echo "")"
      export SLACK_BOT_TOKEN="$(op item get slack-bot --fields token 2>/dev/null || echo "")"
    elif command -v pass >/dev/null 2>&1; then
      # Fallback to pass
      export WORK_API_TOKEN="$(pass show work/api-token 2>/dev/null || echo "")"
      export SLACK_BOT_TOKEN="$(pass show slack/bot-token 2>/dev/null || echo "")"
    fi
    
    # Conditional exports based on directory
    case "$PWD" in
      */work/*)
        # Work directory - use work credentials
        export GIT_CONFIG_GLOBAL="$HOME/.config/git/config-work"
        ;;
      *)
        # Personal projects - use personal credentials
        export GIT_CONFIG_GLOBAL="$HOME/.config/git/config-personal"
        ;;
    esac
  '';
  
in {
  # Make the script available system-wide
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "setup-dev-env" ''
      source ${setupEnvScript}
    '')
  ];
  
  # Auto-source in shell profiles
  programs.zsh.interactiveShellInit = ''
    source ${setupEnvScript}
  '';
  
  # For nushell users
  programs.fish.interactiveShellInit = ''
    source ${setupEnvScript}
  '';
}
