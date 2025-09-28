#!/usr/bin/env zsh

# Set up 1Password for secure git credentials
# Usage: setup-1password-secrets.sh [--personal-name NAME] [--personal-email EMAIL] [--work-name NAME] [--work-email EMAIL]

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
PERSONAL_NAME=""
PERSONAL_EMAIL=""
WORK_NAME=""
WORK_EMAIL=""
SHOW_HELP=false

# Function to show help
show_help() {
    echo "Set up 1Password for secure git credentials"
    echo ""
    echo "Usage: setup-1password-secrets.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --personal-name NAME    Personal git name"
    echo "  --personal-email EMAIL  Personal git email"
    echo "  --work-name NAME        Work git name"
    echo "  --work-email EMAIL      Work git email"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  setup-1password-secrets.sh --personal-name 'John Doe' --personal-email 'john@example.com'"
    echo "  setup-1password-secrets.sh --work-email 'john.doe@company.com'"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --personal-name)
            PERSONAL_NAME="$2"
            shift 2
            ;;
        --personal-email)
            PERSONAL_EMAIL="$2"
            shift 2
            ;;
        --work-name)
            WORK_NAME="$2"
            shift 2
            ;;
        --work-email)
            WORK_EMAIL="$2"
            shift 2
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

# Check if 1Password CLI is available
if ! command -v op >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: 1Password CLI is not installed${NC}"
    echo "Install it with: brew install --cask 1password-cli"
    exit 1
fi

# Check if 1Password is signed in
if ! op account list >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  1Password CLI found but not signed in${NC}"
    echo "Please sign in first with: op signin"
    exit 1
fi

echo "🔐 Setting up 1Password git credentials..."
echo ""

# Function to create or update 1Password item
create_or_update_item() {
    local item_name="$1"
    local vault="$2"
    local name_value="$3"
    local email_value="$4"
    
    # Check if item exists
    if op item get "$item_name" --vault="$vault" >/dev/null 2>&1; then
        echo "📝 Updating existing item: $item_name"
        
        # Update fields
        if [[ -n "$name_value" ]]; then
            op item edit "$item_name" --vault="$vault" "name=$name_value" >/dev/null 2>&1
        fi
        
        if [[ -n "$email_value" ]]; then
            op item edit "$item_name" --vault="$vault" "email=$email_value" >/dev/null 2>&1
        fi
    else
        echo "➕ Creating new item: $item_name"
        
        # Create new item
        op item create --category="Secure Note" \
            --title="$item_name" \
            --vault="$vault" \
            ${name_value:+"name=$name_value"} \
            ${email_value:+"email=$email_value"} >/dev/null 2>&1
    fi
}

# Set up personal credentials
if [[ -n "$PERSONAL_NAME" || -n "$PERSONAL_EMAIL" ]]; then
    echo "📧 Setting up personal git credentials..."
    
    # Create Personal vault if it doesn't exist
    op vault get "Personal" >/dev/null 2>&1 || {
        echo "Creating Personal vault..."
        op vault create "Personal" >/dev/null 2>&1
    }
    
    create_or_update_item "personal-git" "Personal" "$PERSONAL_NAME" "$PERSONAL_EMAIL"
    
    if [[ -n "$PERSONAL_NAME" ]]; then
        echo -e "${GREEN}✅ Personal name set: $PERSONAL_NAME${NC}"
    fi
    
    if [[ -n "$PERSONAL_EMAIL" ]]; then
        echo -e "${GREEN}✅ Personal email set: $PERSONAL_EMAIL${NC}"
    fi
fi

# Set up work credentials
if [[ -n "$WORK_NAME" || -n "$WORK_EMAIL" ]]; then
    echo "🏢 Setting up work git credentials..."
    
    # Create Work vault if it doesn't exist
    op vault get "Work" >/dev/null 2>&1 || {
        echo "Creating Work vault..."
        op vault create "Work" >/dev/null 2>&1
    }
    
    create_or_update_item "work-git" "Work" "$WORK_NAME" "$WORK_EMAIL"
    
    if [[ -n "$WORK_NAME" ]]; then
        echo -e "${GREEN}✅ Work name set: $WORK_NAME${NC}"
    fi
    
    if [[ -n "$WORK_EMAIL" ]]; then
        echo -e "${GREEN}✅ Work email set: $WORK_EMAIL${NC}"
    fi
fi

# Interactive setup if no credentials were provided
if [[ -z "$PERSONAL_NAME" && -z "$PERSONAL_EMAIL" && -z "$WORK_NAME" && -z "$WORK_EMAIL" ]]; then
    echo ""
    echo "🔧 Interactive setup - you can skip any fields by pressing Enter"
    echo ""
    
    # Personal credentials
    echo "📧 Personal Git Configuration:"
    read -p "Personal name (for git commits): " input_personal_name
    read -p "Personal email: " input_personal_email
    
    if [[ -n "$input_personal_name" || -n "$input_personal_email" ]]; then
        # Create Personal vault if it doesn't exist
        op vault get "Personal" >/dev/null 2>&1 || {
            echo "Creating Personal vault..."
            op vault create "Personal" >/dev/null 2>&1
        }
        
        create_or_update_item "personal-git" "Personal" "$input_personal_name" "$input_personal_email"
        
        if [[ -n "$input_personal_name" ]]; then
            echo -e "${GREEN}✅ Personal name set: $input_personal_name${NC}"
        fi
        
        if [[ -n "$input_personal_email" ]]; then
            echo -e "${GREEN}✅ Personal email set: $input_personal_email${NC}"
        fi
    fi
    
    echo ""
    echo "🏢 Work Git Configuration:"
    read -p "Work name (for git commits): " input_work_name
    read -p "Work email: " input_work_email
    
    if [[ -n "$input_work_name" || -n "$input_work_email" ]]; then
        # Create Work vault if it doesn't exist
        op vault get "Work" >/dev/null 2>&1 || {
            echo "Creating Work vault..."
            op vault create "Work" >/dev/null 2>&1
        }
        
        create_or_update_item "work-git" "Work" "$input_work_name" "$input_work_email"
        
        if [[ -n "$input_work_name" ]]; then
            echo -e "${GREEN}✅ Work name set: $input_work_name${NC}"
        fi
        
        if [[ -n "$input_work_email" ]]; then
            echo -e "${GREEN}✅ Work email set: $input_work_email${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}🎉 1Password setup complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Run 'update-git-secrets' to update your git configuration"
echo "2. Your credentials are now stored securely in 1Password"
echo "3. You can view them in the 1Password app or with: op item get personal-git"
echo "4. You can edit them in the 1Password app"
echo ""
echo "📝 Available items:"
echo "  Personal vault: $(op item list --vault=Personal --format=json 2>/dev/null | jq -r '.[].title' | grep -E '^(personal-git)$' || echo 'No git items')"
echo "  Work vault: $(op item list --vault=Work --format=json 2>/dev/null | jq -r '.[].title' | grep -E '^(work-git)$' || echo 'No git items')"

exit 0
