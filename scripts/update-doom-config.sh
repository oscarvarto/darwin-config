#!/usr/bin/env zsh

# Update Doom Emacs configuration with user details and shell settings
# Usage: update-doom-config.sh [--hostname HOSTNAME] [--user USER] [--full-name "Full Name"] [--email "email@domain.com"]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
HOSTNAME_ARG=""
USER_ARG=""
FULL_NAME_ARG=""
EMAIL_ARG=""
DRY_RUN=false
SHOW_HELP=false

# Function to show help
show_help() {
    echo "Update Doom Emacs configuration with user details and shell settings"
    echo ""
    echo "Usage: update-doom-config.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --hostname HOST        Target hostname (defaults to current hostname)"
    echo "  -u, --user USER        Target username (defaults to current \$USER)"
    echo "  -n, --full-name NAME   User's full name for Emacs configuration"
    echo "  -e, --email EMAIL      User's email address for Emacs configuration"
    echo "  -d, --dry-run          Show what would be changed without making changes"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "If full name or email are not provided, they will be derived from the"
    echo "nix configuration based on the user and hostname."
    echo ""
    echo "Examples:"
    echo "  update-doom-config.sh"
    echo "  update-doom-config.sh --hostname alice-macbook --user alice"
    echo "  update-doom-config.sh --full-name \"Alice Smith\" --email \"alice@example.com\""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --hostname)
            HOSTNAME_ARG="$2"
            shift 2
            ;;
        -u|--user)
            USER_ARG="$2"
            shift 2
            ;;
        -n|--full-name)
            FULL_NAME_ARG="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL_ARG="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
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

# Get current system info
CURRENT_USER="${USER}"
CURRENT_HOSTNAME=$(hostname -s)

# Use provided values or defaults
TARGET_USER="${USER_ARG:-$CURRENT_USER}"
TARGET_HOSTNAME="${HOSTNAME_ARG:-$CURRENT_HOSTNAME}"

echo -e "${BLUE}🔧 Updating Doom Emacs configuration${NC}"
echo "  Target User: $TARGET_USER"
echo "  Target Hostname: $TARGET_HOSTNAME"
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

# Check if Doom Emacs config file exists
DOOM_CONFIG_FILE="./stow/doom-emacs/.doom.d/config/core/my-defaults-config.el"
if [[ ! -f "$DOOM_CONFIG_FILE" ]]; then
    echo -e "${RED}❌ Error: Doom Emacs config file not found${NC}"
    echo "Expected: $DOOM_CONFIG_FILE"
    exit 1
fi

# Extract configuration from flake.nix if not provided via arguments
if [[ -z "$FULL_NAME_ARG" || -z "$EMAIL_ARG" ]]; then
    echo "🔍 Reading configuration from flake.nix..."
    
    # Check if the hostname exists in flake.nix
    if ! grep -q "$TARGET_HOSTNAME" flake.nix; then
        echo -e "${RED}❌ Error: Configuration for $TARGET_HOSTNAME not found in flake.nix${NC}"
        echo "Available configurations:"
        grep -E "^\s*[a-zA-Z0-9_-]+ = {" flake.nix | sed 's/.*\(\w\+\) = {.*/  \1/'
        exit 1
    fi

    # Get hostSettings for the target hostname using grep
    if grep -A 10 "$TARGET_HOSTNAME = {" flake.nix | grep -q "workProfile = true"; then
        WORK_PROFILE="true"
    elif grep -A 10 "$TARGET_HOSTNAME = {" flake.nix | grep -q "workProfile = false"; then
        WORK_PROFILE="false"
    else
        WORK_PROFILE="false"
    fi
    
    if grep -A 10 "$TARGET_HOSTNAME = {" flake.nix | grep -q "enablePersonalConfig = true"; then
        PERSONAL_CONFIG="true"
    elif grep -A 10 "$TARGET_HOSTNAME = {" flake.nix | grep -q "enablePersonalConfig = false"; then
        PERSONAL_CONFIG="false"
    else
        PERSONAL_CONFIG="false"
    fi
    
    echo "  Work Profile: ${WORK_PROFILE:-false}"
    echo "  Personal Config: ${PERSONAL_CONFIG:-false}"
fi

# Derive user details if not provided
if [[ -z "$FULL_NAME_ARG" ]]; then
    # Try to derive full name from username
    case "$TARGET_USER" in
        "oscarvarto")
            FULL_NAME_ARG="Oscar Vargas Torres"
            ;;
        *)
            # Create a reasonable default from username
            FULL_NAME_ARG=$(echo "$TARGET_USER" | sed 's/\(.\)/\U\1/' | sed 's/[._-]/ /g')
            ;;
    esac
fi

if [[ -z "$EMAIL_ARG" ]]; then
    # Derive email based on personal config setting
    if [[ "$PERSONAL_CONFIG" == "true" ]]; then
        case "$TARGET_USER" in
            "oscarvarto")
                EMAIL_ARG="contact@oscarvarto.mx"
                ;;
            *)
                EMAIL_ARG="${TARGET_USER}@users.noreply.github.com"
                ;;
        esac
    else
        EMAIL_ARG="${TARGET_USER}@company.com"
    fi
fi

echo ""
echo "📝 Configuration to apply:"
echo "  Full Name: $FULL_NAME_ARG"
echo "  Email: $EMAIL_ARG"

# Get the default shell from nix configuration
echo ""
echo "🐚 Determining default shell from nix configuration..."

DEFAULT_SHELL=$(grep -A 10 "$TARGET_HOSTNAME = {" flake.nix | grep 'defaultShell = ' | sed 's/.*defaultShell = "\([^"]*\)".*/\1/')

# Default to nushell if not specified (for backward compatibility)
DEFAULT_SHELL="${DEFAULT_SHELL:-nushell}"

echo "  Default Shell: $DEFAULT_SHELL"

# Map shell names to their paths (matching system.nix configuration)
case "$DEFAULT_SHELL" in
    "zsh")
        SHELL_PATH="/run/current-system/sw/bin/zsh"
        ;;
    "fish")
        SHELL_PATH="/Users/$TARGET_USER/.nix-profile/bin/fish"
        ;;
    "nushell")
        SHELL_PATH="/Users/$TARGET_USER/.nix-profile/bin/nu"
        ;;
    *)
        echo -e "${YELLOW}⚠️  Warning: Unknown shell '$DEFAULT_SHELL', defaulting to nushell${NC}"
        SHELL_PATH="/Users/$TARGET_USER/.nix-profile/bin/nu"
        ;;
esac

echo "  Shell Path: $SHELL_PATH"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "📋 Changes that would be made to $DOOM_CONFIG_FILE:"
    echo "  - Update user-full-name to: \"$FULL_NAME_ARG\""
    echo "  - Update user-mail-address to: \"$EMAIL_ARG\""
    echo "  - Update vterm-shell to: (executable-find \"$(basename "$SHELL_PATH")\")"
    exit 0
fi

# Create a backup of the config file
BACKUP_FILE="$DOOM_CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
cp "$DOOM_CONFIG_FILE" "$BACKUP_FILE"
echo ""
echo "💾 Created backup: $BACKUP_FILE"

# Update the configuration file
echo "✏️  Updating Doom Emacs configuration..."

# Use sed to update the user configuration
sed -i.tmp \
    -e "s|^(setq user-full-name \".*\"|;; Updated by update-doom-config.sh on $(date)\n(setq user-full-name \"$FULL_NAME_ARG\"|" \
    -e "s|user-mail-address \".*\")|user-mail-address \"$EMAIL_ARG\")|" \
    "$DOOM_CONFIG_FILE"

# Update the vterm-shell setting
# Extract just the shell executable name for the executable-find call
SHELL_EXECUTABLE=$(basename "$SHELL_PATH")

sed -i.tmp2 \
    -e "s|^(setq-default vterm-shell (executable-find \".*\"))|;; Updated by update-doom-config.sh on $(date)\n(setq-default vterm-shell (executable-find \"$SHELL_EXECUTABLE\"))|" \
    "$DOOM_CONFIG_FILE"

# Remove the temporary files created by sed
rm -f "$DOOM_CONFIG_FILE.tmp" "$DOOM_CONFIG_FILE.tmp2"

echo -e "${GREEN}✅ Successfully updated Doom Emacs configuration${NC}"
echo ""

# Show the changes
echo "📋 Applied changes:"
echo "  ✓ User full name: $FULL_NAME_ARG"
echo "  ✓ User email: $EMAIL_ARG"
echo "  ✓ VTerm shell: $SHELL_EXECUTABLE (from $SHELL_PATH)"

echo ""
echo "🔄 Next steps:"
echo "1. Restart Emacs or reload the configuration to apply changes"
echo "2. The backup file is available at: $BACKUP_FILE"
echo "3. You can verify the changes with: grep -A2 -B1 'user-\\(full-name\\|mail-address\\)\\|vterm-shell' '$DOOM_CONFIG_FILE'"

exit 0
