# Enhanced secret management with agenix integration
{
  config,
  pkgs,
  agenix,
  user,
  ...
}: {
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
          cd "$SECRETS_DIR" && "$AGENIX_BIN" -e "$1.age"
      }

      agenix_create() {
          cd "$SECRETS_DIR" && "$AGENIX_BIN" -e "$1.age"
      }

      agenix_rekey() {
          cd "$SECRETS_DIR" && "$AGENIX_BIN" -r
      }

      agenix_show() {
          cd "$SECRETS_DIR" && "$AGENIX_BIN" -d "$1.age"
      }

      agenix_list() {
          find "$SECRETS_DIR" -name "*.age" -exec basename {} .age \;
      }

      status_check() {
          echo "🔐 Secret Management Status"
          echo "=========================="
          echo ""

          # agenix status
          echo "📁 agenix secrets:"
          if [[ -d "$SECRETS_DIR" ]]; then
              find "$SECRETS_DIR" -name "*.age" | wc -l | xargs echo "  Encrypted files:"
          else
              echo "  ❌ Secrets directory not found: $SECRETS_DIR"
          fi

          # 1Password status
          echo ""
          echo "🔑 1Password:"
          if command -v op >/dev/null 2>&1; then
              if op account list >/dev/null 2>&1; then
                  echo "  ✅ Available and signed in"
                  op vault list --format=table | head -5
              else
                  echo "  ⚠️  Available but not signed in"
              fi
          else
              echo "  ❌ Not installed"
          fi

          # pass status
          echo ""
          echo "🗝️  pass:"
          if command -v pass >/dev/null 2>&1; then
              echo "  ✅ Available"
              pass ls 2>/dev/null | head -5 || echo "  📭 No entries found"
          else
              echo "  ❌ Not installed"
          fi
      }

      case "''${1:-}" in
          edit|e)      agenix_edit "''${2:-}" ;;
          create|c)    agenix_create "''${2:-}" ;;
          rekey|r)     agenix_rekey ;;
          show|s)      agenix_show "''${2:-}" ;;
          list|ls)     agenix_list ;;
          op-get)      op item get "''${2:-}" ;;
          op-set)      echo "Use 1Password app or: op item create" ;;
          pass-get)    pass show "''${2:-}" ;;
          pass-set)    pass insert "''${2:-}" ;;
          sync-git)    update-git-secrets ;;
          status)      status_check ;;
          help|--help|-h) usage ;;
          *)           usage; exit 1 ;;
      esac
    '')

    # Backup script for all credential systems
    (pkgs.writeShellScriptBin "backup-secrets" ''
      #!/usr/bin/env bash
      set -euo pipefail

      BACKUP_DIR="$HOME/secret-backups/$(date +%Y-%m-%d)"
      mkdir -p "$BACKUP_DIR"

      echo "🔐 Backing up secrets to: $BACKUP_DIR"

      # Backup agenix secrets (encrypted)
      if [[ -d "$HOME/nix-secrets" ]]; then
          echo "📁 Backing up agenix secrets..."
          cp -r "$HOME/nix-secrets" "$BACKUP_DIR/agenix-secrets"
      fi

      # Backup 1Password export (if available)
      if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
          echo "🔑 Exporting 1Password vault list..."
          op vault list --format=json > "$BACKUP_DIR/1password-vaults.json"
      fi

      # Backup pass store
      if [[ -d "$HOME/.password-store" ]]; then
          echo "🗝️  Backing up pass store..."
          cp -r "$HOME/.password-store" "$BACKUP_DIR/password-store"
      fi

      echo "✅ Backup completed: $BACKUP_DIR"
    '')
  ];
}
