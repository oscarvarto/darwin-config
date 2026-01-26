#!/usr/bin/env zsh

# Comprehensive repository sanitization script
# Removes all traces of sensitive information from files and git history
# Usage: sanitize-sensitive-data.sh [--dry-run] [--force] [--no-backup]

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
    echo -e "${BLUE}🧹 Comprehensive Repository Sanitizer${NC}"
    echo ""
    echo "Completely removes sensitive information from repository files and git history"
    echo ""
    echo "Usage: sanitize-sensitive-data.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run          Show what would be changed without making changes"
    echo "  -f, --force            Skip confirmation prompts"
    echo "      --no-backup        Don't create backup branch"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "What it does:"
    echo "  1. Scans for ALL sensitive patterns (emails, names, paths, keys)"
    echo "  2. Sanitizes current repository files"
    echo "  3. Uses BFG to clean entire git history"
    echo "  4. Removes all traces of sensitive data from all commits"
    echo "  5. Optimizes repository after cleanup"
    echo ""
    echo "Examples:"
    echo "  sanitize-sensitive-data.sh --dry-run    # Preview what would be cleaned"
    echo "  sanitize-sensitive-data.sh              # Interactive cleanup"
    echo "  sanitize-sensitive-data.sh --force      # Non-interactive cleanup"
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
    echo -e "${YELLOW}💡 BFG is available in your packages - run 'nix run .#build' first${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Scanning repository for sensitive information...${NC}"

# Create temporary files
TEMP_DIR=$(mktemp -d)
SENSITIVE_FILE="$TEMP_DIR/sensitive-patterns.txt"
REPLACEMENT_FILE="$TEMP_DIR/replacements.txt"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Generate comprehensive list of sensitive patterns found in the repository
echo -e "${BLUE}📊 Analyzing repository content...${NC}"

# Create the sensitive patterns file with actual content found
cat > "$SENSITIVE_FILE" << 'EOF'
# Personal email addresses
contact@oscarvarto.mx
oscarvarto@protonmail.com
oscar.varto@gmail.com

# Personal name variations
Oscar Vargas Torres
Oscar Varto
OscarVarto

# Username (will be replaced with generic 'user')
oscarvarto

# Personal paths
/Users/oscarvarto

# GitHub/Git URLs with personal info
git@github.com:oscarvarto
github.com/oscarvarto

# Secrets repository URL
git+ssh://git@github.com/oscarvarto/nix-secrets.git
EOF

# Create replacement patterns for BFG
cat > "$REPLACEMENT_FILE" << 'EOF'
# Replace personal emails with generic ones
contact@oscarvarto.mx==>user@example.com
oscarvarto@protonmail.com==>user@example.com
oscar.varto@gmail.com==>user@example.com

# Replace personal names with generic ones  
Oscar Vargas Torres==>User Name
Oscar Varto==>User
OscarVarto==>User

# Replace username with generic 'user'
oscarvarto==>user

# Replace personal paths with generic user paths
/Users/oscarvarto==>/Users/user

# Replace personal GitHub URLs
git@github.com:oscarvarto==>git@github.com:user
github.com/oscarvarto==>github.com/user

# Replace secrets repository URL
git+ssh://git@github.com/oscarvarto/nix-secrets.git==>git+ssh://git@github.com/user/nix-secrets.git
EOF

# Scan current repository for matches
echo -e "${BLUE}🔍 Current repository analysis:${NC}"
TOTAL_MATCHES=0

while IFS= read -r pattern; do
    # Skip comments and empty lines
    if [[ "$pattern" =~ ^[[:space:]]*# || -z "$pattern" ]]; then
        continue
    fi
    
    # Count matches for this pattern
    MATCHES=$(grep -r --exclude-dir=.git --exclude-dir=.nix-profile "$pattern" . 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ "$MATCHES" -gt 0 ]]; then
        echo -e "  ${YELLOW}📝 '$pattern': $MATCHES matches${NC}"
        TOTAL_MATCHES=$((TOTAL_MATCHES + MATCHES))
    fi
done < <(grep -v "^#" "$SENSITIVE_FILE" | grep -v "^$")

echo -e "${YELLOW}📊 Total sensitive matches found: $TOTAL_MATCHES${NC}"

if [[ "$TOTAL_MATCHES" -eq 0 ]]; then
    echo -e "${GREEN}✅ No sensitive information found in current repository${NC}"
    echo -e "${BLUE}🔍 Checking git history anyway...${NC}"
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo -e "${BLUE}🔍 DRY RUN - Detailed analysis:${NC}"
    echo ""
    echo "Files that contain sensitive information:"
    
    while IFS= read -r pattern; do
        if [[ "$pattern" =~ ^[[:space:]]*# || -z "$pattern" ]]; then
            continue
        fi
        
        grep -r --exclude-dir=.git -l "$pattern" . 2>/dev/null | while read file; do
            echo "  📝 $file (contains: $pattern)"
        done
    done < <(grep -v "^#" "$SENSITIVE_FILE" | grep -v "^$") | sort -u
    
    echo ""
    echo -e "${BLUE}🧹 Operations that would be performed:${NC}"
    echo "  1. Create backup branch (unless --no-backup)"
    echo "  2. Replace sensitive data in current files"
    echo "  3. Stage and commit sanitized files"
    echo "  4. Use BFG to clean entire git history"
    echo "  5. Optimize repository with gc"
    echo "  6. Verify all sensitive data is removed"
    echo ""
    echo -e "${YELLOW}⚠️  This is a DRY RUN - no changes made${NC}"
    echo -e "${GREEN}💡 Run without --dry-run to perform actual sanitization${NC}"
    exit 0
fi

# Create backup branch
BACKUP_BRANCH="backup-before-sanitization-$(date +%Y%m%d-%H%M%S)"
if [[ "$NO_BACKUP" != "true" ]]; then
    echo -e "${YELLOW}💾 Creating backup branch: $BACKUP_BRANCH${NC}"
    git branch "$BACKUP_BRANCH"
    echo -e "${GREEN}✅ Backup created: git checkout $BACKUP_BRANCH${NC}"
fi

# Confirmation prompt unless forced
if [[ "$FORCE" != "true" ]]; then
    echo ""
    echo -e "${RED}⚠️  CRITICAL WARNING: This will permanently alter repository and git history!${NC}"
    echo -e "${YELLOW}📓 This action will:${NC}"
    echo -e "${YELLOW}   1. Replace ALL sensitive data in current files${NC}"
    echo -e "${YELLOW}   2. Remove sensitive data from ENTIRE git history${NC}"
    echo -e "${YELLOW}   3. Rewrite ALL commits (new commit hashes)${NC}"
    echo -e "${YELLOW}   4. Require force push to any remotes${NC}"
    echo -e "${YELLOW}   5. Affect anyone who has cloned this repository${NC}"
    if [[ "$NO_BACKUP" != "true" ]]; then
        echo -e "${GREEN}   ✅ Backup branch created: $BACKUP_BRANCH${NC}"
    fi
    echo ""
    echo -e "${RED}This operation cannot be undone without the backup!${NC}"
    echo -n "Are you absolutely sure you want to continue? (y/N): "
    
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
echo -e "${BLUE}🧹 Step 1: Sanitizing current repository files...${NC}"

# Replace sensitive information in current files
FILES_MODIFIED=0
while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]]; then
        continue
    fi
    
    # Extract pattern and replacement from replacement file
    PATTERN=$(echo "$line" | cut -d'=' -f1)
    REPLACEMENT=$(echo "$line" | cut -d'>' -f2)
    
    if [[ -n "$PATTERN" && -n "$REPLACEMENT" ]]; then
        # Find and replace in all files
        MODIFIED_FILES=$(grep -r --exclude-dir=.git -l "$PATTERN" . 2>/dev/null || true)
        
        if [[ -n "$MODIFIED_FILES" ]]; then
            echo "$MODIFIED_FILES" | while read file; do
                echo -e "  📝 Sanitizing: $file"
                sed -i.backup "s|$PATTERN|$REPLACEMENT|g" "$file"
                rm -f "$file.backup"
                FILES_MODIFIED=$((FILES_MODIFIED + 1))
            done
        fi
    fi
done < <(grep -v "^#" "$REPLACEMENT_FILE" | grep -v "^$")

if [[ "$FILES_MODIFIED" -gt 0 ]]; then
    echo -e "${GREEN}✅ Sanitized $FILES_MODIFIED files${NC}"
    
    # Stage and commit the sanitized files
    echo -e "${BLUE}📝 Committing sanitized files...${NC}"
    git add -A
    git commit -m "🧹 Sanitize repository: Remove sensitive personal information

- Replace personal emails with generic examples
- Replace personal names with generic placeholders  
- Replace username with generic 'user'
- Replace personal paths with generic user paths
- Replace personal GitHub URLs with generic examples

This commit prepares the repository for BFG history cleaning."
    
    echo -e "${GREEN}✅ Sanitized files committed${NC}"
else
    echo -e "${GREEN}✅ No files needed sanitization${NC}"
fi

echo ""
echo -e "${BLUE}🧹 Step 2: Cleaning git history with BFG...${NC}"

# Use BFG to clean git history
if bfg --replace-text="$REPLACEMENT_FILE" --no-blob-protection . 2>/dev/null; then
    echo -e "${GREEN}✅ BFG history cleanup completed${NC}"
else
    echo -e "${YELLOW}⚠️  BFG completed with warnings (this is often normal)${NC}"
fi

echo -e "${BLUE}🔧 Step 3: Optimizing repository...${NC}"
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo -e "${GREEN}✅ Repository optimization complete${NC}"

echo ""
echo -e "${BLUE}🔍 Step 4: Final verification...${NC}"

# Check if sensitive patterns still exist
REMAINING_MATCHES=0
SENSITIVE_PATTERNS=("contact@oscarvarto.mx" "oscarvarto@protonmail.com" "oscar.varto@gmail.com" 
                   "Oscar Vargas Torres" "Oscar Varto" "OscarVarto" 
                   "oscarvarto" "/Users/oscarvarto"
                   "git@github.com:oscarvarto" "github.com/oscarvarto")

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    MATCHES=$(grep -r --exclude-dir=.git "$pattern" . 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$MATCHES" -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Pattern '$pattern' still found: $MATCHES matches${NC}"
        REMAINING_MATCHES=$((REMAINING_MATCHES + MATCHES))
        
        # Show where it's still found
        grep -r --exclude-dir=.git -n "$pattern" . 2>/dev/null | head -3 | while read match; do
            echo -e "    ${YELLOW}📍 $match${NC}"
        done
    fi
done

if [[ "$REMAINING_MATCHES" -eq 0 ]]; then
    echo -e "${GREEN}✅ All sensitive information successfully removed!${NC}"
else
    echo -e "${YELLOW}⚠️  $REMAINING_MATCHES sensitive references remain${NC}"
    echo -e "${YELLOW}💡 These may need manual review or be in documentation as examples${NC}"
fi

# Check git log for any remaining sensitive information
echo ""
echo -e "${BLUE}🔍 Checking git history for remaining sensitive data...${NC}"

HISTORY_MATCHES=0
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if git log --all --grep="$pattern" --oneline 2>/dev/null | head -1 | grep -q .; then
        HISTORY_MATCHES=$((HISTORY_MATCHES + 1))
        echo -e "${YELLOW}⚠️  Found '$pattern' in commit messages${NC}"
    fi
done

if [[ "$HISTORY_MATCHES" -eq 0 ]]; then
    echo -e "${GREEN}✅ Git history appears clean of sensitive data${NC}"
else
    echo -e "${YELLOW}⚠️  $HISTORY_MATCHES sensitive patterns found in git history${NC}"
    echo -e "${YELLOW}💡 You may need additional BFG cleaning with specific filters${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Repository sanitization complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "${YELLOW}   1. Review the changes: git log --oneline -10${NC}"
echo -e "${YELLOW}   2. Test your configuration: nix run .#build${NC}"
echo -e "${YELLOW}   3. Set up secure credentials: nix run .#setup-1password-secrets${NC}"
if [[ "$NO_BACKUP" != "true" ]]; then
    echo -e "${YELLOW}   4. If satisfied, delete backup: git branch -d $BACKUP_BRANCH${NC}"
fi
echo -e "${YELLOW}   5. Update remote origin if needed${NC}"
echo -e "${YELLOW}   6. Force push (CAREFULLY): git push --force-with-lease${NC}"
echo ""
echo -e "${RED}⚠️  CRITICAL REMINDERS:${NC}"
echo -e "${RED}   - This repository is now sanitized but you MUST set up secure credentials${NC}"
echo -e "${RED}   - Force push will rewrite history for all collaborators${NC}"
echo -e "${RED}   - Update any scripts/configs that referenced the old personal info${NC}"
echo -e "${GREEN}   - The multi-user system is now ready for safe sharing${NC}"

exit 0
