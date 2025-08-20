#!/usr/bin/env zsh

# Add a new host configuration to flake.nix
# Usage: add-host.sh --hostname HOSTNAME --user USER [--system SYSTEM] [--work-profile] [--personal-config]

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
SYSTEM_ARG="aarch64-darwin"
WORK_PROFILE=false
PERSONAL_CONFIG=false
DRY_RUN=false
SHOW_HELP=false

# Function to show help
show_help() {
    echo "Add a new host configuration to flake.nix"
    echo ""
    echo "Usage: add-host.sh --hostname HOSTNAME --user USER [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  --hostname HOST        Target hostname"
    echo "  -u, --user USER        Target username"
    echo ""
    echo "Options:"
    echo "  -s, --system ARCH      System architecture (default: aarch64-darwin)"
    echo "  -w, --work-profile     Enable work profile configuration"
    echo "  -p, --personal-config  Enable personal configuration"
    echo "  -d, --dry-run          Show what would be changed without making changes"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  add-host.sh --hostname alice-macbook --user alice --personal-config"
    echo "  add-host.sh --hostname work-laptop --user bob --work-profile --system x86_64-darwin"
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
        -s|--system)
            SYSTEM_ARG="$2"
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

# Validate required parameters
if [[ -z "$HOSTNAME_ARG" ]]; then
    echo -e "${RED}❌ Error: --hostname is required${NC}"
    show_help
    exit 1
fi

if [[ -z "$USER_ARG" ]]; then
    echo -e "${RED}❌ Error: --user is required${NC}"
    show_help
    exit 1
fi

# Validate system architecture
if [[ "$SYSTEM_ARG" != "aarch64-darwin" && "$SYSTEM_ARG" != "x86_64-darwin" ]]; then
    echo -e "${RED}❌ Error: Invalid system '$SYSTEM_ARG'. Must be 'aarch64-darwin' or 'x86_64-darwin'${NC}"
    exit 1
fi

echo "Adding host configuration:"
echo "  Hostname: $HOSTNAME_ARG"
echo "  User: $USER_ARG"
echo "  System: $SYSTEM_ARG"
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

# Read current flake.nix
FLAKE_CONTENT=$(cat flake.nix)

# Check if hostname already exists in configuration
if echo "$FLAKE_CONTENT" | grep -q "$HOSTNAME_ARG"; then
    echo -e "${RED}❌ Error: Configuration for $HOSTNAME_ARG already exists in flake.nix${NC}"
    echo "Use a different hostname or update the existing configuration manually"
    exit 1
fi

# Create the new host configuration text
NEW_HOST_CONFIG="        $HOSTNAME_ARG = {
          user = \"$USER_ARG\";
          system = \"$SYSTEM_ARG\";
          hostSettings = {
            enablePersonalConfig = $PERSONAL_CONFIG;
            workProfile = $WORK_PROFILE;
          };
        };"

echo "New host configuration:"
echo "$NEW_HOST_CONFIG"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "This would be added to the hostConfigs section in flake.nix"
    exit 0
fi

# Create a backup of flake.nix
cp flake.nix flake.nix.backup

# Find the position to insert the new configuration
# Look for the closing brace of hostConfigs
TEMP_FILE=$(mktemp)

# Use Python to safely insert the configuration
python3 << EOF > "$TEMP_FILE"
import sys

# Read the flake.nix file
with open('flake.nix', 'r') as f:
    lines = f.readlines()

# Find the hostConfigs section and insert the new configuration
new_config = '''$NEW_HOST_CONFIG
'''

result_lines = []
in_host_configs = False
brace_count = 0
inserted = False

for line in lines:
    if 'hostConfigs = {' in line:
        in_host_configs = True
        brace_count = 1
        result_lines.append(line)
        continue
    
    if in_host_configs:
        # Count braces to find the end of hostConfigs
        brace_count += line.count('{') - line.count('}')
        
        # If we reach the end of hostConfigs section and haven't inserted yet
        if brace_count == 0 and not inserted:
            result_lines.append(new_config)
            inserted = True
            in_host_configs = False
    
    result_lines.append(line)

# Write the result
with open('$TEMP_FILE', 'w') as f:
    f.writelines(result_lines)
EOF

# Check if insertion was successful
if ! grep -q "$HOSTNAME_ARG" "$TEMP_FILE"; then
    echo -e "${RED}❌ Error: Could not find hostConfigs section in flake.nix${NC}"
    echo "Please add the host configuration manually"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Replace the original file
mv "$TEMP_FILE" flake.nix

echo -e "${GREEN}✅ Added host configuration to flake.nix${NC}"
echo ""

# Test the build
echo "🚀 Testing build for new configuration..."
if nix build ".#darwinConfigurations.$HOSTNAME_ARG.system" --show-trace 2>/dev/null; then
    echo -e "${GREEN}✅ Build successful for $HOSTNAME_ARG configuration${NC}"
    echo ""
    echo -e "${GREEN}🎉 Host configuration for $HOSTNAME_ARG has been successfully added!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Set up the user account for '$USER_ARG' on the target system"
    echo "2. Copy this flake to the new system"
    echo "3. Run 'nix run .#configure-user --hostname $HOSTNAME_ARG --user $USER_ARG' on the target system"
    echo "4. Apply the configuration with 'nix run .#build-switch'"
    echo "5. Update Doom Emacs configuration with 'nix run .#update-doom-config --hostname $HOSTNAME_ARG --user $USER_ARG'"
    
    # Remove backup since everything worked
    rm -f flake.nix.backup
    
else
    echo -e "${RED}❌ Build failed for $HOSTNAME_ARG configuration${NC}"
    
    # Restore the backup
    mv flake.nix.backup flake.nix
    echo ""
    echo -e "${RED}❌ Reverted changes to flake.nix due to build failure${NC}"
    echo "Please check the configuration and try again"
    exit 1
fi

exit 0
