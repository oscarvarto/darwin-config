{ config, pkgs, lib, user, hostSettings, ... }:

let
  # Helper scripts for secure credential retrieval
  getCredentialScript = secretType: pkgs.writeShellScript "get-${secretType}" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Default values based on host settings
    DEFAULT_PERSONAL_EMAIL="''${USER}@users.noreply.github.com"
    DEFAULT_WORK_EMAIL="''${USER}@company.com"
    DEFAULT_NAME="''${USER}"
    
    # Function to get secret from 1Password
    get_from_1password() {
        local item="$1"
        local field="$2"
        local vault="$3"
        
        if command -v op >/dev/null 2>&1; then
            if op account list >/dev/null 2>&1; then
                local vault_arg=""
                if [[ -n "$vault" ]]; then
                    vault_arg="--vault=$vault"
                fi
                op item get "$item" --fields "$field" $vault_arg 2>/dev/null || return 1
            else
                return 1
            fi
        else
            return 1
        fi
    }
    
    # Function to get secret from pass
    get_from_pass() {
        local path="$1"
        local field="$2"
        
        if command -v pass >/dev/null 2>&1; then
            if [[ "$field" == "password" ]]; then
                pass show "$path" 2>/dev/null | head -n1 || return 1
            else
                pass show "$path" 2>/dev/null | grep "^$field:" | cut -d':' -f2- | sed 's/^ *//' || return 1
            fi
        else
            return 1
        fi
    }
    
    # Function to get git user name
    get_git_name() {
        local profile="$1"  # personal or work
        
        # Try 1Password first
        local name=""
        if [[ "$profile" == "personal" ]]; then
            name=$(get_from_1password "personal-git" "name" "Personal" 2>/dev/null || true)
            if [[ -z "$name" ]]; then
                name=$(get_from_pass "git/personal" "name" 2>/dev/null || true)
            fi
        else
            name=$(get_from_1password "work-git" "name" "Work" 2>/dev/null || true)
            if [[ -z "$name" ]]; then
                name=$(get_from_pass "git/work" "name" 2>/dev/null || true)
            fi
        fi
        
        # Fallback to default
        echo "''${name:-$DEFAULT_NAME}"
    }
    
    # Function to get git user email
    get_git_email() {
        local profile="$1"  # personal or work
        
        # Try 1Password first
        local email=""
        if [[ "$profile" == "personal" ]]; then
            email=$(get_from_1password "personal-git" "email" "Personal" 2>/dev/null || true)
            if [[ -z "$email" ]]; then
                email=$(get_from_pass "git/personal" "email" 2>/dev/null || true)
            fi
            # Fallback to default personal email
            echo "''${email:-$DEFAULT_PERSONAL_EMAIL}"
        else
            email=$(get_from_1password "work-git" "email" "Work" 2>/dev/null || true)
            if [[ -z "$email" ]]; then
                email=$(get_from_pass "git/work" "email" 2>/dev/null || true)
            fi
            # Fallback to default work email
            echo "''${email:-$DEFAULT_WORK_EMAIL}"
        fi
    }
    
    # Main logic based on secret type
    case "${secretType}" in
        "git-name-personal")
            get_git_name "personal"
            ;;
        "git-name-work")
            get_git_name "work"
            ;;
        "git-email-personal")
            get_git_email "personal"
            ;;
        "git-email-work")
            get_git_email "work"
            ;;
        *)
            echo "Unknown secret type: ${secretType}" >&2
            exit 1
            ;;
    esac
  '';

  # Create dynamic git configuration files
  createGitConfig = profile: pkgs.writeText "git-config-${profile}" ''
    [user]
    	name = placeholder_name
    	email = placeholder_email
    [core]
    	editor = nvim
    [init]
    	defaultBranch = main
    [pull]
    	rebase = true
    [push]
    	autoSetupRemote = true
  '';

  # Script to update git configuration files with secrets
  updateGitConfigScript = pkgs.writeShellScript "update-git-configs" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    CONFIG_DIR="$HOME/.config/git"
    mkdir -p "$CONFIG_DIR"
    
    # Update personal git config
    PERSONAL_NAME=$(${getCredentialScript "git-name-personal"})
    PERSONAL_EMAIL=$(${getCredentialScript "git-email-personal"})
    
    cat > "$CONFIG_DIR/config-personal" << EOF
    [user]
    	name = $PERSONAL_NAME
    	email = $PERSONAL_EMAIL
    [core]
    	editor = nvim
    [init]
    	defaultBranch = main
    [pull]
    	rebase = true
    [push]
    	autoSetupRemote = true
    EOF
    
    # Update work git config
    WORK_NAME=$(${getCredentialScript "git-name-work"})
    WORK_EMAIL=$(${getCredentialScript "git-email-work"})
    
    cat > "$CONFIG_DIR/config-work" << EOF
    [user]
    	name = $WORK_NAME
    	email = $WORK_EMAIL
    [core]
    	editor = nvim
    [init]
    	defaultBranch = main
    [pull]
    	rebase = true
    [push]
    	autoSetupRemote = true
    [commit]
    	gpgsign = false
    EOF
    
    echo "✅ Git configurations updated with secure credentials"
    echo "📧 Personal: $PERSONAL_NAME <$PERSONAL_EMAIL>"
    echo "🏢 Work: $WORK_NAME <$WORK_EMAIL>"
  '';

in
{
  # Install credential management tools
  environment.systemPackages = with pkgs; [
    _1password-cli  # 1Password CLI
    pass           # pass (password-store) as alternative
    gnupg          # Required for pass
  ];

  # Create helper scripts for secret management
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "update-git-secrets" ''
      exec ${updateGitConfigScript}
    '')
    
    (pkgs.writeShellScriptBin "get-git-secret" ''
      #!/usr/bin/env bash
      if [[ $# -ne 1 ]]; then
          echo "Usage: get-git-secret <secret-type>"
          echo "Secret types: git-name-personal, git-name-work, git-email-personal, git-email-work"
          exit 1
      fi
      exec ${getCredentialScript "$1"}
    '')
    
    (pkgs.writeShellScriptBin "setup-git-secrets" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      echo "🔐 Setting up Git credential management"
      echo ""
      echo "This script will help you configure secure git credentials using either:"
      echo "1. 1Password CLI (recommended if you have a subscription)"
      echo "2. pass (password-store) - free alternative"
      echo ""
      
      # Check available tools
      if command -v op >/dev/null 2>&1; then
          echo "✅ 1Password CLI is available"
          if op account list >/dev/null 2>&1; then
              echo "✅ 1Password is signed in"
          else
              echo "⚠️  1Password CLI found but not signed in. Run 'op signin' first."
          fi
      else
          echo "❌ 1Password CLI not found"
      fi
      
      if command -v pass >/dev/null 2>&1; then
          echo "✅ pass (password-store) is available"
      else
          echo "❌ pass not found"
      fi
      
      echo ""
      echo "📋 To set up credentials:"
      echo ""
      echo "For 1Password:"
      echo "1. Create items named 'personal-git' and 'work-git'"
      echo "2. Add 'name' and 'email' fields to each item"
      echo "3. Organize them in 'Personal' and 'Work' vaults (optional)"
      echo ""
      echo "For pass:"
      echo "1. Run: pass insert git/personal"
      echo "2. Add metadata: pass insert git/personal/name"
      echo "3. Add metadata: pass insert git/personal/email"
      echo "4. Repeat for git/work/*"
      echo ""
      echo "Then run: update-git-secrets"
    '')
  ];

  # User-level launchd agent to update git configs on login
  launchd.user.agents.updateGitSecrets = {
    serviceConfig = {
      Label = "org.nixos.updateGitSecrets";
      ProgramArguments = [ "${updateGitConfigScript}" ];
      RunAtLoad = true;
      # Run every 6 hours to refresh credentials
      StartInterval = 21600;
    };
  };
}
