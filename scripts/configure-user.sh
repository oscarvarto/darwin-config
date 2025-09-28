#!/usr/bin/env zsh

# Configure darwin-config for a different user and hostname
# Usage: configure-user.sh [--user USER] [--hostname HOSTNAME] [--work-profile] [--personal-config]

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
USER_ARG=""
HOSTNAME_ARG=""
WORK_PROFILE=false
PERSONAL_CONFIG=false
DRY_RUN=false
SHOW_HELP=false

# Function to show help
show_help() {
    echo "Configure darwin-config for a different user and hostname"
    echo ""
    echo "Usage: configure-user.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --user USER        Target username (defaults to current \$USER)"
    echo "  -h, --hostname HOST    Target hostname (defaults to current hostname)"
    echo "  -w, --work-profile     Enable work profile configuration"
    echo "  -p, --personal-config  Enable personal configuration"
    echo "  -d, --dry-run          Show what would be changed without making changes"
    echo "      --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  configure-user.sh --user alice --hostname alice-macbook"
    echo "  configure-user.sh --user bob --hostname work-laptop --work-profile"
    echo "  configure-user.sh --dry-run  # Preview changes for current user/hostname"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            USER_ARG="$2"
            shift 2
            ;;
        -h|--hostname)
            HOSTNAME_ARG="$2"
            shift 2
            ;;
        -w|--work-profile)
            WORK_PROFILE=true
            shift
            ;;
        -p|--personal-config)
            PERSONAL_CONFIG=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
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

# Get current system info
CURRENT_USER="${USER}"
CURRENT_HOSTNAME=$(hostname -s)

# Use provided values or defaults
TARGET_USER="${USER_ARG:-$CURRENT_USER}"
TARGET_HOSTNAME="${HOSTNAME_ARG:-$CURRENT_HOSTNAME}"

echo "Configuring darwin-config for:"
echo "  User: $TARGET_USER"
echo "  Hostname: $TARGET_HOSTNAME"
echo "  Work Profile: $WORK_PROFILE"
echo "  Personal Config: $PERSONAL_CONFIG"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}🔍 DRY RUN - No changes will be made${NC}"
    echo ""
fi

# Check if flake.nix exists
if [[ ! -f "flake.nix" ]]; then
    echo -e "${RED}❌ Error: flake.nix not found in current directory${NC}"
    echo "Please run this script from the darwin-config directory"
    exit 1
fi

# Read flake.nix and check if hostname exists
FLAKE_CONTENT=$(cat flake.nix)

if echo "$FLAKE_CONTENT" | grep -q "$TARGET_HOSTNAME"; then
    echo -e "${GREEN}✅ Configuration for $TARGET_HOSTNAME already exists in flake.nix${NC}"
else
    echo -e "${YELLOW}⚠️  Configuration for $TARGET_HOSTNAME not found in flake.nix${NC}"
    echo "You'll need to add it manually to the hostConfigs section"
    echo ""
    echo "Add this to your flake.nix hostConfigs:"
    echo "  \"$TARGET_HOSTNAME\" = {"
    echo "    user = \"$TARGET_USER\";"
    echo "    system = \"aarch64-darwin\";"
    echo "    defaultShell = \"zsh\";  # Options: \"zsh\", \"nushell\", \"fish\""
    echo "    hostSettings = {"
    echo "      enablePersonalConfig = $PERSONAL_CONFIG;"
    echo "      workProfile = $WORK_PROFILE;"
    echo "    };"
    echo "  };"
    echo ""
fi

# Check if we're already on the target user/hostname
if [[ "$TARGET_USER" == "$CURRENT_USER" && "$TARGET_HOSTNAME" == "$CURRENT_HOSTNAME" ]]; then
    echo -e "${GREEN}✅ Already configured for the target user and hostname${NC}"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        echo ""
        echo "Running build to ensure configuration is up to date..."
        nix run .#build
        
        echo ""
        echo "🔧 Updating Doom Emacs configuration for current user..."
        nix run .#update-doom-config
    fi
    exit 0
fi

# Check for potential issues
TARGET_HOME="/Users/$TARGET_USER"
if [[ ! -d "$TARGET_HOME" ]]; then
    echo -e "${YELLOW}⚠️  Warning: User home directory $TARGET_HOME does not exist${NC}"
    echo "Make sure the user account exists before applying the configuration"
fi

# Files that might need updating
FILES_TO_CHECK=("secrets/secrets.nix" "secrets/age-keys.txt" ".envrc")

echo "🔍 Checking for files that might need manual updates:"
for file in "${FILES_TO_CHECK[@]}"; do
    if [[ -f "$file" ]]; then
        if grep -q "$CURRENT_USER" "$file"; then
            echo "  📝 $file - contains references to $CURRENT_USER"
        fi
    fi
done

if [[ "$DRY_RUN" != "true" ]]; then
    echo ""
    echo "🚀 Testing build for target configuration..."
    
    # Try to build the target configuration
    if nix build ".#darwinConfigurations.$TARGET_HOSTNAME.system" 2>/dev/null; then
        echo -e "${GREEN}✅ Build successful for $TARGET_HOSTNAME configuration${NC}"
        
        echo ""
        echo "🔄 To switch to this configuration, run:"
        echo "   sudo darwin-rebuild switch --flake .#$TARGET_HOSTNAME"
        echo ""
        echo "Or use the build-switch app:"
        echo "   nix run .#build-switch"
        
    else
        echo -e "${RED}❌ Build failed for $TARGET_HOSTNAME configuration${NC}"
        echo "Check the flake configuration and try again"
        exit 1
    fi
fi

echo ""
echo "📋 Next steps:"
echo "1. Update any secrets or personal files for the new user"
echo "2. Ensure the user account exists on the system"
echo "3. Run 'nix run .#build-switch' to apply the configuration"
echo "4. Set up any user-specific applications or data"

exit 0
