#!/usr/bin/env zsh

# Sanitize repository of all sensitive information
# Usage: sanitize-repo.sh [--dry-run] [--force] [--no-backup]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [[ -z "${DARWIN_CONFIG_PATH:-}" ]]; then
    echo -e "${RED}❌ DARWIN_CONFIG_PATH is not set. Run 'nix run .#record-config-path' and restart your shell.${NC}"
    exit 1
fi

cd "${DARWIN_CONFIG_PATH}" || {
    echo -e "${RED}❌ Cannot change directory to DARWIN_CONFIG_PATH=${DARWIN_CONFIG_PATH}${NC}"
    exit 1
}

# Default values
DRY_RUN=false
FORCE=false
NO_BACKUP=false
SHOW_HELP=false

# Function to show help
show_help() {
    echo -e "${BLUE}🧹 Repository Sanitizer${NC}"
    echo ""
    echo "Completely removes sensitive information from repository files and git history"
    echo ""
    echo "Usage: sanitize-repo.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run          Show what would be changed without making changes"
    echo "  -f, --force            Skip confirmation prompts"
    echo "      --no-backup        Don't create backup branch"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "What it does:"
    echo "  1. Scans for hardcoded sensitive information"
    echo "  2. Creates sanitized versions of affected files"
    echo "  3. Uses BFG to clean git history"
    echo "  4. Removes all traces of sensitive data"
    echo ""
    echo "Examples:"
    echo "  sanitize-repo.sh --dry-run    # Preview what would be cleaned"
    echo "  sanitize-repo.sh              # Interactive cleanup"
    echo "  sanitize-repo.sh --force      # Non-interactive cleanup"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

if [[ "$SHOW_HELP" == "true" ]]; then
    show_help
    exit 0
fi

# Check if we're in a git repository
if [[ ! -d ".git" ]]; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${RED}❌ Repository has uncommitted changes${NC}"
    echo -e "${YELLOW}💡 Commit or stash your changes first${NC}"
    exit 1
fi

# Check if BFG is available
if ! command -v bfg >/dev/null 2>&1; then
    echo -e "${RED}❌ BFG not found${NC}"
    echo -e "${YELLOW}💡 Install it with: brew install bfg${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Scanning for sensitive information...${NC}"

# Create temporary files for sensitive data patterns
SENSITIVE_PATTERNS_FILE=$(mktemp)
REPLACEMENT_FILE=$(mktemp)

# Cleanup function
cleanup() {
    rm -f "$SENSITIVE_PATTERNS_FILE" "$REPLACEMENT_FILE"
}
trap cleanup EXIT

# Patterns to search for and replace
cat > "$SENSITIVE_PATTERNS_FILE" << 'EOF'
# Email addresses
contact@oscarvarto.mx
oscarvarto@protonmail.com
oscar.varto@gmail.com

# Personal name variations
Oscar Vargas Torres
Oscar Varto
OscarVarto

# Specific usernames and paths
oscarvarto
/Users/oscarvarto

# SSH key patterns (if any leaked)
ssh-rsa AAAAB3NzaC1yc2E
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5

# Potential API keys or tokens (generic patterns)
ghp_[a-zA-Z0-9]{36}
github_pat_[a-zA-Z0-9_]{82}

# Database connection strings (if any)
mysql://.*@
postgresql://.*@
mongodb://.*@

# Other potentially sensitive patterns
password.*=.*[^{\s]
token.*=.*[^{\s]
secret.*=.*[^{\s]
api.*key.*=.*[^{\s]
EOF

# BFG replacement patterns (what to replace with)
cat > "$REPLACEMENT_FILE" << 'EOF'
# Replace emails with generic ones
contact@oscarvarto.mx==>user@example.com
oscarvarto@protonmail.com==>user@example.com
oscar.varto@gmail.com==>user@example.com

# Replace personal names
Oscar Vargas Torres==>User Name
Oscar Varto==>User
OscarVarto==>User

# Replace usernames and paths
oscarvarto==>user
/Users/oscarvarto==>/Users/user

# Replace SSH keys with placeholders
ssh-rsa AAAAB3NzaC1yc2E==>ssh-rsa PLACEHOLDER_RSA_KEY
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5==>ssh-ed25519 PLACEHOLDER_ED25519_KEY

# Replace API keys with placeholders
ghp_==>GITHUB_PAT_PLACEHOLDER_
github_pat_==>GITHUB_PAT_PLACEHOLDER_

# Replace database connections
mysql://==>mysql://user:password@localhost/
postgresql://==>postgresql://user:password@localhost/
mongodb://==>mongodb://user:password@localhost/

# Replace other sensitive patterns
password=secret==>password=placeholder
token=secret==>token=placeholder
secret=value==>secret=placeholder
api-key=value==>api-key=placeholder
EOF

echo -e "${YELLOW}🔍 Found these potential sensitive patterns:${NC}"
grep -v "^#" "$SENSITIVE_PATTERNS_FILE" | grep -v "^$" | while read line; do
    echo "  - $line"
done

echo ""
echo -e "${BLUE}📊 Scanning current repository for matches...${NC}"

# Count matches in current repository
MATCH_COUNT=0
while read pattern; do
    if [[ "$pattern" =~ ^[[:space:]]*# || -z "$pattern" ]]; then
        continue
    fi
    
    # Search for pattern in repository (excluding .git directory)
    MATCHES=$(grep -r --exclude-dir=.git "$pattern" . 2>/dev/null | wc -l || echo "0")
    if [[ "$MATCHES" -gt 0 ]]; then
        echo -e "  ${YELLOW}📝 Pattern '$pattern': $MATCHES matches${NC}"
        MATCH_COUNT=$((MATCH_COUNT + MATCHES))
    fi
done < "$SENSITIVE_PATTERNS_FILE"

if [[ "$MATCH_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}✅ No sensitive patterns found in current repository${NC}"
    echo ""
    echo "Checking git history for sensitive data..."
else
    echo -e "${YELLOW}📊 Total matches found: $MATCH_COUNT${NC}"
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo -e "${BLUE}🔍 DRY RUN - Detailed analysis:${NC}"
    
    echo ""
    echo "Files that would be modified:"
    while read pattern; do
        if [[ "$pattern" =~ ^[[:space:]]*# || -z "$pattern" ]]; then
            continue
        fi
        grep -r --exclude-dir=.git -l "$pattern" . 2>/dev/null | while read file; do
            echo "  📝 $file"
        done
    done < "$SENSITIVE_PATTERNS_FILE" | sort -u
    
    echo ""
    echo -e "${BLUE}🧹 Git history cleanup would:${NC}"
    echo "  1. Create backup branch (unless --no-backup)"
    echo "  2. Use BFG to clean sensitive data from all commits"
    echo "  3. Rewrite git history"
    echo "  4. Run git gc to optimize repository"
    echo ""
    echo -e "${YELLOW}⚠️  This is a DRY RUN - no changes made${NC}"
    exit 0
fi

# First, sanitize current files
echo ""
echo -e "${BLUE}🧹 Step 1: Sanitizing current files...${NC}"

TEMP_DIR=$(mktemp -d)
FILES_MODIFIED=0

while read pattern; do
    if [[ "$pattern" =~ ^[[:space:]]*# || -z "$pattern" ]]; then
        continue
    fi
    
    # Find files containing the pattern
    grep -r --exclude-dir=.git -l "$pattern" . 2>/dev/null | while read file; do
        if [[ ! -f "$TEMP_DIR/$(basename "$file").modified" ]]; then
            echo "  📝 Processing: $file"
            # Create sanitized version
            sed "s|$pattern|SANITIZED_${pattern//[^a-zA-Z0-9]/_}|g" "$file" > "$TEMP_DIR/$(basename "$file").sanitized"
            FILES_MODIFIED=$((FILES_MODIFIED + 1))
        fi
    done
done < "$SENSITIVE_PATTERNS_FILE"

# Backup branch
BACKUP_BRANCH="backup-before-sanitization-$(date +%Y%m%d-%H%M%S)"
if [[ "$NO_BACKUP" != "true" ]]; then
    echo -e "${YELLOW}💾 Creating backup branch: $BACKUP_BRANCH${NC}"
    git branch "$BACKUP_BRANCH"
    echo -e "${GREEN}✅ Backup created: git checkout $BACKUP_BRANCH${NC}"
fi

# Confirmation prompt unless forced
if [[ "$FORCE" != "true" ]]; then
    echo ""
    echo -e "${RED}⚠️  WARNING: This will permanently alter git history and current files!${NC}"
    echo -e "${YELLOW}📓 This action will:${NC}"
    echo -e "${YELLOW}   1. Replace sensitive data in current files${NC}"
    echo -e "${YELLOW}   2. Remove sensitive data from ALL commits${NC}"
    echo -e "${YELLOW}   3. Rewrite git history${NC}"
    echo -e "${YELLOW}   4. Change commit hashes${NC}"
    echo -e "${YELLOW}   5. Require force push if pushed to remote${NC}"
    if [[ "$NO_BACKUP" != "true" ]]; then
        echo -e "${GREEN}   ✅ Backup branch created: $BACKUP_BRANCH${NC}"
    fi
    echo ""
    echo -n "Are you sure you want to continue? (y/N): "
    
    read reply
    if [[ "$reply" != "y" && "$reply" != "Y" ]]; then
        echo -e "${YELLOW}🚫 Operation cancelled${NC}"
        if [[ "$NO_BACKUP" != "true" ]]; then
            git branch -d "$BACKUP_BRANCH" 2>/dev/null || true
        fi
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}🧹 Step 2: Cleaning git history with BFG...${NC}"

# Use BFG to clean git history
if bfg --replace-text="$REPLACEMENT_FILE" --no-blob-protection .; then
    echo -e "${GREEN}✅ BFG cleanup completed successfully${NC}"
    
    echo -e "${BLUE}🔧 Step 3: Optimizing repository...${NC}"
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
    
    echo -e "${GREEN}✅ Repository optimization complete${NC}"
else
    echo -e "${RED}❌ BFG cleanup failed${NC}"
    if [[ "$NO_BACKUP" != "true" ]]; then
        echo -e "${GREEN}🔄 Restore from backup: git checkout $BACKUP_BRANCH${NC}"
    fi
    exit 1
fi

echo ""
echo -e "${BLUE}🧹 Step 4: Final verification...${NC}"

# Check if sensitive patterns still exist
REMAINING_MATCHES=0
while read pattern; do
    if [[ "$pattern" =~ ^[[:space:]]*# || -z "$pattern" ]]; then
        continue
    fi
    
    MATCHES=$(grep -r --exclude-dir=.git "$pattern" . 2>/dev/null | wc -l || echo "0")
    if [[ "$MATCHES" -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Pattern '$pattern' still found: $MATCHES matches${NC}"
        REMAINING_MATCHES=$((REMAINING_MATCHES + MATCHES))
    fi
done < "$SENSITIVE_PATTERNS_FILE"

if [[ "$REMAINING_MATCHES" -eq 0 ]]; then
    echo -e "${GREEN}✅ All sensitive patterns successfully removed${NC}"
else
    echo -e "${YELLOW}⚠️  $REMAINING_MATCHES sensitive patterns remain${NC}"
    echo -e "${YELLOW}💡 You may need to manually review and clean these${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Repository sanitization complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "${YELLOW}   1. Review the changes: git log --oneline${NC}"
echo -e "${YELLOW}   2. Test your configuration thoroughly${NC}"
echo -e "${YELLOW}   3. Update any references to use secure credential system${NC}"
if [[ "$NO_BACKUP" != "true" ]]; then
    echo -e "${YELLOW}   4. If satisfied, delete backup: git branch -d $BACKUP_BRANCH${NC}"
fi
echo -e "${YELLOW}   5. Force push to remote: git push --force-with-lease origin main${NC}"
echo ""
echo -e "${RED}⚠️  IMPORTANT:${NC}"
echo -e "${RED}   - Force push will affect all collaborators!${NC}"
echo -e "${RED}   - Make sure to set up secure credentials before using git${NC}"
echo -e "${GREEN}   - Run: nix run .#setup-1password-secrets or nix run .#setup-pass-secrets${NC}"

exit 0
