# Enhanced secret management with agenix integration
{ config, pkgs, agenix, user, ... }:

{
  environment.systemPackages = [
    # Enhanced secret management script
    (pkgs.writeShellScriptBin "secret" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      SECRETS_DIR="$HOME/nix-secrets"
      AGENIX_BIN="${agenix.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/agenix"
      
      usage() {
          echo "secret - Enhanced secret management for agenix + 1Password/pass"
          echo ""
          echo "Usage: secret <command> [args]"
          echo ""
          echo "agenix commands:"
          echo "  edit <secret>     Edit agenix secret"
          echo "  create <secret>   Create new agenix secret"
          echo "  rekey            Rekey all agenix secrets"
          echo "  show <secret>    Show decrypted secret content"
          echo "  list             List all available secrets"
          echo ""
          echo "1Password commands:"
          echo "  op-get <item>     Get 1Password item"
          echo "  op-set <item>     Set 1Password item"
          echo ""
          echo "pass commands:"
          echo "  pass-get <path>   Get pass entry"
          echo "  pass-set <path>   Set pass entry"
          echo ""
          echo "hybrid commands:"
          echo "  sync-git         Update git configs from credentials"
          echo "  status           Show status of all credential systems"
      }
      
      agenix_edit() {
          if [[ -z "''${1:-}" ]]; then
              echo "❌ Error: Secret name required"
              echo "Usage: secret edit <secret-name>"
              exit 1
          fi
          cd "$SECRETS_DIR" && "$AGENIX_BIN" -e "$1.age"
      }
      
      agenix_create() {
          if [[ -z "''${1:-}" ]]; then
              echo "❌ Error: Secret name required"
              echo "Usage: secret create <secret-name>"
              exit 1
          fi
          cd "$SECRETS_DIR" && "$AGENIX_BIN" -e "$1.age"
      }
      
      agenix_rekey() {
          cd "$SECRETS_DIR" && "$AGENIX_BIN" -r
      }
      
      agenix_show() {
          if [[ -z "''${1:-}" ]]; then
              echo "❌ Error: Secret name required"
              echo "Usage: secret show <secret-name>"
              exit 1
          fi
          cd "$SECRETS_DIR" && "$AGENIX_BIN" -d "$1.age"
      }
      
      agenix_list() {
          if [[ -d "$SECRETS_DIR" ]]; then
              echo "📁 Available agenix secrets:"
              find "$SECRETS_DIR" -name "*.age" -exec basename {} .age ';' | sort
          else
              echo "❌ Secrets directory not found: $SECRETS_DIR"
              echo "💡 Clone your secrets repo to: $SECRETS_DIR"
          fi
      }
      
      status_check() {
          echo "🔐 Secret Management Status"
          echo "=========================="
          echo ""
          
          # agenix status
          echo "📁 agenix secrets:"
          if [[ -d "$SECRETS_DIR" ]]; then
              local count=$(find "$SECRETS_DIR" -name "*.age" | wc -l | tr -d ' ')
              echo "  ✅ Secrets directory: $SECRETS_DIR"
              echo "  📊 Encrypted files: $count"
              if [[ $count -gt 0 ]]; then
                  echo "  📋 Available secrets:"
                  find "$SECRETS_DIR" -name "*.age" -exec basename {} .age ';' | sort | sed 's/^/    /'
              fi
          else
              echo "  ❌ Secrets directory not found: $SECRETS_DIR"
              echo "  💡 Clone your secrets repo: git clone git@github.com:oscarvarto/nix-secrets.git ~/nix-secrets"
          fi
          
          # SSH keys status
          echo ""
          echo "🔑 SSH Keys:"
          if [[ -f "/Users/${user}/.ssh/id_ed25519" ]]; then
              echo "  ✅ Main SSH key: /Users/${user}/.ssh/id_ed25519"
          else
              echo "  ❌ Main SSH key not found"
          fi
          
          if [[ -f "/Users/${user}/.ssh/id_ed25519_agenix" ]]; then
              echo "  ✅ Agenix SSH key: /Users/${user}/.ssh/id_ed25519_agenix"
          else
              echo "  ⚠️  Agenix SSH key not found (run: ./apps/aarch64-darwin/create-keys)"
          fi
          
          # 1Password status
          echo ""
          echo "🔑 1Password:"
          if command -v op >/dev/null 2>&1; then
              if op account list >/dev/null 2>&1; then
                  echo "  ✅ Available and signed in"
                  local vaults=$(op vault list --format=json 2>/dev/null | jq -r '.[].name' | wc -l | tr -d ' ')
                  echo "  📊 Vaults: $vaults"
              else
                  echo "  ⚠️  Available but not signed in (run: op signin)"
              fi
          else
              echo "  ❌ Not installed (run: brew install --cask 1password-cli)"
          fi
          
          # pass status  
          echo ""
          echo "🗝️  pass:"
          if command -v pass >/dev/null 2>&1; then
              if [[ -d "$HOME/.password-store" ]]; then
                  echo "  ✅ Available and initialized"
                  local entries=$(find "$HOME/.password-store" -name "*.gpg" | wc -l | tr -d ' ')
                  echo "  📊 Entries: $entries"
              else
                  echo "  ⚠️  Available but not initialized (run: pass init <gpg-key-id>)"
              fi
          else
              echo "  ❌ Not installed (run: brew install pass)"
          fi
          
          # Git credential status
          echo ""
          echo "📧 Git Configuration:"
          if [[ -f "$HOME/.config/git/config-personal" ]]; then
              echo "  ✅ Personal config: $HOME/.config/git/config-personal"
          else
              echo "  ⚠️  Personal config not found (run: update-git-secrets)"
          fi
          
          if [[ -f "$HOME/.config/git/config-work" ]]; then
              echo "  ✅ Work config: $HOME/.config/git/config-work"
          else
              echo "  ⚠️  Work config not found (run: update-git-secrets)"
          fi
      }
      
      case "''${1:-}" in
          edit|e)      agenix_edit "''${2:-}" ;;
          create|c)    agenix_create "''${2:-}" ;;
          rekey|r)     agenix_rekey ;;
          show|s)      agenix_show "''${2:-}" ;;
          list|ls)     agenix_list ;;
          op-get)      
              if [[ -z "''${2:-}" ]]; then
                  echo "❌ Error: Item name required"
                  exit 1
              fi
              op item get "''${2:-}" ;;
          op-set)      
              echo "💡 Use 1Password app or: op item create --category='Secure Note' --title='item-name' field1=value1 field2=value2" ;;
          pass-get)    
              if [[ -z "''${2:-}" ]]; then
                  echo "❌ Error: Path required"
                  exit 1
              fi
              pass show "''${2:-}" ;;
          pass-set)    
              if [[ -z "''${2:-}" ]]; then
                  echo "❌ Error: Path required"
                  exit 1
              fi
              pass insert "''${2:-}" ;;
          sync-git)    
              if command -v update-git-secrets >/dev/null 2>&1; then
                  update-git-secrets
              else
                  echo "❌ update-git-secrets command not found"
                  echo "💡 Make sure secure-credentials.nix module is loaded"
              fi ;;
          status)      status_check ;;
          help|--help|-h|"") usage ;;
          *)           
              echo "❌ Unknown command: $1"
              usage
              exit 1 ;;
      esac
    '')
    
    # Backup script for all credential systems
    (pkgs.writeShellScriptBin "backup-secrets" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      BACKUP_DIR="$HOME/secret-backups/$(date +%Y-%m-%d_%H-%M-%S)"
      mkdir -p "$BACKUP_DIR"
      
      echo "🔐 Backing up secrets to: $BACKUP_DIR"
      echo ""
      
      # Backup agenix secrets (encrypted)
      if [[ -d "$HOME/nix-secrets" ]]; then
          echo "📁 Backing up agenix secrets..."
          cp -r "$HOME/nix-secrets" "$BACKUP_DIR/agenix-secrets"
          echo "  ✅ Agenix secrets backed up"
      else
          echo "  ⚠️  No agenix secrets directory found"
      fi
      
      # Backup SSH keys
      if [[ -d "$HOME/.ssh" ]]; then
          echo "🔑 Backing up SSH keys..."
          mkdir -p "$BACKUP_DIR/ssh-keys"
          # Only backup private keys (be careful with permissions)
          find "$HOME/.ssh" -name "id_*" -not -name "*.pub" -exec cp {} "$BACKUP_DIR/ssh-keys/" ';' 2>/dev/null || true
          # Backup SSH config
          [[ -f "$HOME/.ssh/config" ]] && cp "$HOME/.ssh/config" "$BACKUP_DIR/ssh-keys/"
          echo "  ✅ SSH keys backed up"
      fi
      
      # Backup 1Password vault list (if available)
      if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
          echo "🔑 Exporting 1Password vault info..."
          op vault list --format=json > "$BACKUP_DIR/1password-vaults.json" 2>/dev/null || true
          op item list --format=json > "$BACKUP_DIR/1password-items.json" 2>/dev/null || true
          echo "  ✅ 1Password info exported"
      else
          echo "  ⚠️  1Password not available for backup"
      fi
      
      # Backup pass store
      if [[ -d "$HOME/.password-store" ]]; then
          echo "🗝️  Backing up pass store..."
          cp -r "$HOME/.password-store" "$BACKUP_DIR/password-store"
          echo "  ✅ Pass store backed up"
      else
          echo "  ⚠️  No pass store found"
      fi
      
      # Backup git configs
      if [[ -d "$HOME/.config/git" ]]; then
          echo "📧 Backing up git configs..."
          cp -r "$HOME/.config/git" "$BACKUP_DIR/git-configs"
          echo "  ✅ Git configs backed up"
      fi
      
      echo ""
      echo "✅ Backup completed!"
      echo "📁 Location: $BACKUP_DIR"
      echo ""
      echo "⚠️  Security reminder:"
      echo "   - This backup contains private keys and encrypted secrets"
      echo "   - Store it securely (encrypted drive, secure cloud storage)"
      echo "   - Consider encrypting the backup directory itself"
      echo ""
      echo "💡 To encrypt this backup:"
      echo "   tar -czf secrets-backup.tar.gz -C $(dirname $BACKUP_DIR) $(basename $BACKUP_DIR)"
      echo "   gpg -c secrets-backup.tar.gz"
    '')
    
    # Quick secret setup script
    (pkgs.writeShellScriptBin "setup-secrets-repo" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      SECRETS_DIR="$HOME/nix-secrets"
      
      if [[ -d "$SECRETS_DIR" ]]; then
          echo "✅ Secrets repository already exists at: $SECRETS_DIR"
          exit 0
      fi
      
      echo "🔐 Setting up secrets repository..."
      echo ""
      
      # Check if SSH key exists
      if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
          echo "❌ SSH key not found. Run first:"
          echo "   ./apps/aarch64-darwin/create-keys"
          exit 1
      fi
      
      # Clone the secrets repository
      echo "📥 Cloning secrets repository..."
      if git clone git@github.com:oscarvarto/nix-secrets.git "$SECRETS_DIR"; then
          echo "✅ Secrets repository cloned successfully"
          echo ""
          echo "📋 Next steps:"
          echo "1. Run: secret list (to see available secrets)"
          echo "2. Run: secret create <secret-name> (to create new secrets)"
          echo "3. Run: secret status (to check system status)"
      else
          echo "❌ Failed to clone secrets repository"
          echo "💡 Make sure you have access to: git@github.com:oscarvarto/nix-secrets.git"
          exit 1
      fi
    '')
  ];
}
