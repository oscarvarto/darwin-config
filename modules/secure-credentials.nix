{
  config,
  pkgs,
  lib,
  user,
  hostSettings,
  ...
}: let
  # Helper scripts for secure credential retrieval
  getCredentialScript = secretType:
    pkgs.writeShellScript "get-${secretType}" ''
      #!/usr/bin/env bash
      set -eo pipefail

      # No fallback defaults - credentials must come from 1Password or pass
      # This prevents overwriting valid configs when credential stores are unavailable

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
                  # Use timeout to prevent hanging, and ensure proper field access
                  timeout 5 op item get "$item" --fields "label=$field" "$vault_arg" 2>/dev/null || return 1
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

          # Try 1Password first, then pass - return empty if neither has the data
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

          # Return empty if credentials unavailable - NO fallback to defaults
          # This allows the update script to preserve existing valid configs
          echo "$name"
      }

      # Function to get git user email
      get_git_email() {
          local profile="$1"  # personal or work

          # Try 1Password first, then pass - return empty if neither has the data
          local email=""
          if [[ "$profile" == "personal" ]]; then
              email=$(get_from_1password "personal-git" "email" "Personal" 2>/dev/null || true)
              if [[ -z "$email" ]]; then
                  email=$(get_from_pass "git/personal" "email" 2>/dev/null || true)
              fi
          else
              email=$(get_from_1password "work-git" "email" "Work" 2>/dev/null || true)
              if [[ -z "$email" ]]; then
                  email=$(get_from_pass "git/work" "email" 2>/dev/null || true)
              fi
          fi

          # Return empty if credentials unavailable - NO fallback to defaults
          # This allows the update script to preserve existing valid configs
          echo "$email"
      }

      # Function to get JIRA API token
      get_jira_api_token() {
          local profile="$1"  # personal or work

          # Try 1Password first, then pass - return empty if neither has the data
          local token=""
          if [[ "$profile" == "personal" ]]; then
              # For personal JIRA, try common item names
              token=$(get_from_1password "jira-api-token" "token" "Personal" 2>/dev/null || true)
              if [[ -z "$token" ]]; then
                  token=$(get_from_1password "jira-personal" "api-token" "Personal" 2>/dev/null || true)
              fi
              if [[ -z "$token" ]]; then
                  token=$(get_from_pass "jira/personal/api-token" "password" 2>/dev/null || true)
              fi
          else
              # For work JIRA, use environment variables
              local work_op_vault="''${WORK_OP_VAULT:-Work}"
              local work_op_item="''${WORK_OP_ITEM:-CompanyName}"
              token=$(get_from_1password "''${work_op_item}-jira-api" "api-token" "''${work_op_vault}" 2>/dev/null || true)
              if [[ -z "$token" ]]; then
                  token=$(get_from_1password "jira-work" "token" "''${work_op_vault}" 2>/dev/null || true)
              fi
              if [[ -z "$token" ]]; then
                  token=$(get_from_pass "jira/work/api-token" "password" 2>/dev/null || true)
              fi
          fi

          # Return empty if credentials unavailable - NO fallback to defaults
          echo "$token"
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
          "jira-api-token-personal")
              get_jira_api_token "personal"
              ;;
          "jira-api-token-work")
              get_jira_api_token "work"
              ;;
          *)
              echo "Unknown secret type: ${secretType}" >&2
              exit 1
              ;;
      esac
    '';

  # Create dynamic git configuration files
  createGitConfig = profile:
    pkgs.writeText "git-config-${profile}" ''
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

        # Try to fetch credentials, but don't fail if unavailable
        PERSONAL_NAME=$(${getCredentialScript "git-name-personal"} 2>/dev/null || echo "")
        PERSONAL_EMAIL=$(${getCredentialScript "git-email-personal"} 2>/dev/null || echo "")
        WORK_NAME=$(${getCredentialScript "git-name-work"} 2>/dev/null || echo "")
        WORK_EMAIL=$(${getCredentialScript "git-email-work"} 2>/dev/null || echo "")

        # Function to check if config needs update (has placeholder or default values)
        needs_update() {
            local config_file="$1"
            if [[ ! -f "$config_file" ]]; then
                return 0  # File doesn't exist, needs creation
            fi
            # Check if config contains placeholder or default values
            if grep -q "placeholder_name\|placeholder_email\|@users.noreply.github.com\|@company.com\|@example.com" "$config_file" 2>/dev/null; then
                return 0  # Contains placeholders, needs update
            fi
            return 1  # Config looks good, don't update
        }

        # Update personal git config only if needed and credentials are available
        if [[ -n "$PERSONAL_NAME" ]] && [[ -n "$PERSONAL_EMAIL" ]]; then
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
            echo "✅ Personal config updated: $PERSONAL_NAME <$PERSONAL_EMAIL>"
        elif needs_update "$CONFIG_DIR/config-personal"; then
            echo "⚠️  Personal config has placeholders but credentials unavailable"
            echo "   Run 'secret status' to check 1Password/pass setup"
        else
            echo "✓ Personal config preserved (credentials unavailable, but config looks good)"
        fi

        # Update work git config only if needed and credentials are available
        if [[ -n "$WORK_NAME" ]] && [[ -n "$WORK_EMAIL" ]]; then
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
            echo "✅ Work config updated: $WORK_NAME <$WORK_EMAIL>"
        elif needs_update "$CONFIG_DIR/config-work"; then
            echo "⚠️  Work config has placeholders but credentials unavailable"
            echo "   Run 'secret status' to check 1Password/pass setup"
        else
            echo "✓ Work config preserved (credentials unavailable, but config looks good)"
        fi
  '';
in {
  # Install credential management tools and helper scripts
  environment.systemPackages = with pkgs;
    [
      _1password-cli # 1Password CLI
      pass # pass (password-store) as alternative
      gnupg # Required for pass
    ]
    ++ [
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

      (pkgs.writeShellScriptBin "get-jira-api-token" ''
        #!/usr/bin/env bash
        # Get JIRA API token from secure storage
        profile="''${1:-work}"
        if [[ "$profile" != "personal" ]] && [[ "$profile" != "work" ]]; then
            echo "Usage: get-jira-api-token [personal|work]"
            echo "Default: work"
            exit 1
        fi
        # Call the appropriate credential script based on profile
        if [[ "$profile" == "personal" ]]; then
            exec ${getCredentialScript "jira-api-token-personal"}
        else
            exec ${getCredentialScript "jira-api-token-work"}
        fi
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

      (pkgs.writeShellScriptBin "setup-jira-secrets" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo "🔐 Setting up JIRA API token management"
        echo ""
        echo "This script will help you configure secure JIRA API tokens using either:"
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
        echo "📋 To set up JIRA API tokens:"
        echo ""
        echo "For 1Password (Recommended):"
        echo "1. Create an item named 'jira-api-token' in your Personal vault"
        echo "2. Add a field named 'token' with your JIRA API token"
        echo "3. For work JIRA, create 'CompanyName-jira-api' in your Work vault"
        echo "4. Add a field named 'api-token' with your work JIRA API token"
        echo ""
        echo "For pass:"
        echo "1. Personal: pass insert jira/personal/api-token"
        echo "2. Work: pass insert jira/work/api-token"
        echo ""
        echo "Test with: get-jira-api-token personal"
        echo "Or: get-jira-api-token work"
      '')
    ];

  # User-level launchd agent to update git configs on login
  launchd.user.agents.updateGitSecrets = {
    serviceConfig = {
      Label = "org.nixos.updateGitSecrets";
      ProgramArguments = ["${updateGitConfigScript}"];
      RunAtLoad = true;
      # Run once a week (credentials rarely change)
      # You can manually run 'update-git-secrets' anytime if needed
      StartInterval = 604800;
    };
  };
}
