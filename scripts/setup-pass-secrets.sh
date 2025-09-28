#!/usr/bin/env zsh

# Set up pass (password-store) for secure git credentials
# Usage: setup-pass-secrets.sh [--personal-name NAME] [--personal-email EMAIL] [--work-name NAME] [--work-email EMAIL]

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
    echo "Set up pass (password-store) for secure git credentials"
    echo ""
    echo "Usage: setup-pass-secrets.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --personal-name NAME    Personal git name"
    echo "  --personal-email EMAIL  Personal git email"
    echo "  --work-name NAME        Work git name"  
    echo "  --work-email EMAIL      Work git email"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  setup-pass-secrets.sh --personal-name 'John Doe' --personal-email 'john@example.com'"
    echo "  setup-pass-secrets.sh --work-email 'john.doe@company.com'"
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

# Check if pass is available
if ! command -v pass >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: pass (password-store) is not installed${NC}"
    echo "Install it with: brew install pass"
    exit 1
fi

# Check if GPG is set up
if ! gpg --list-secret-keys >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  No GPG keys found. Setting up GPG for pass...${NC}"
    echo ""
    echo "Generating a new GPG key for pass:"
    echo "1. You'll be prompted for your name and email"
    echo "2. Choose a strong passphrase"
    echo "3. The key will be used to encrypt your password store"
    echo ""
    
    # Generate GPG key non-interactively
    cat > /tmp/gpg-gen-key << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${USER}
Name-Email: ${USER}@$(hostname)
Expire-Date: 0
Passphrase: 
%commit
EOF
    
    gpg --batch --generate-key /tmp/gpg-gen-key
    rm -f /tmp/gpg-gen-key
    
    echo -e "${GREEN}✅ GPG key generated${NC}"
fi

# Initialize pass if not already done
if [[ ! -d "$HOME/.password-store" ]]; then
    echo "🔐 Initializing password store..."
    
    # Get the GPG key ID
    GPG_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | head -n1 | awk '{print $2}' | cut -d'/' -f2)
    
    if [[ -z "$GPG_ID" ]]; then
        echo -e "${RED}❌ Error: Could not find GPG key${NC}"
        exit 1
    fi
    
    pass init "$GPG_ID"
    echo -e "${GREEN}✅ Password store initialized with GPG key: $GPG_ID${NC}"
fi

echo ""
echo "🔧 Setting up git credentials in pass..."

# Set up personal credentials
if [[ -n "$PERSONAL_NAME" || -n "$PERSONAL_EMAIL" ]]; then
    echo ""
    echo "📧 Setting up personal git credentials..."
    
    # Create a dummy password for the git/personal entry
    echo "dummy" | pass insert -m git/personal >/dev/null 2>&1
    
    if [[ -n "$PERSONAL_NAME" ]]; then
        echo "$PERSONAL_NAME" | pass insert -m git/personal/name >/dev/null 2>&1
        echo -e "${GREEN}✅ Personal name set: $PERSONAL_NAME${NC}"
    fi
    
    if [[ -n "$PERSONAL_EMAIL" ]]; then
        echo "$PERSONAL_EMAIL" | pass insert -m git/personal/email >/dev/null 2>&1
        echo -e "${GREEN}✅ Personal email set: $PERSONAL_EMAIL${NC}"
    fi
fi

# Set up work credentials  
if [[ -n "$WORK_NAME" || -n "$WORK_EMAIL" ]]; then
    echo ""
    echo "🏢 Setting up work git credentials..."
    
    # Create a dummy password for the git/work entry
    echo "dummy" | pass insert -m git/work >/dev/null 2>&1
    
    if [[ -n "$WORK_NAME" ]]; then
        echo "$WORK_NAME" | pass insert -m git/work/name >/dev/null 2>&1
        echo -e "${GREEN}✅ Work name set: $WORK_NAME${NC}"
    fi
    
    if [[ -n "$WORK_EMAIL" ]]; then
        echo "$WORK_EMAIL" | pass insert -m git/work/email >/dev/null 2>&1
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
        echo "dummy" | pass insert -m git/personal >/dev/null 2>&1
        
        if [[ -n "$input_personal_name" ]]; then
            echo "$input_personal_name" | pass insert -m git/personal/name >/dev/null 2>&1
            echo -e "${GREEN}✅ Personal name set: $input_personal_name${NC}"
        fi
        
        if [[ -n "$input_personal_email" ]]; then
            echo "$input_personal_email" | pass insert -m git/personal/email >/dev/null 2>&1
            echo -e "${GREEN}✅ Personal email set: $input_personal_email${NC}"
        fi
    fi
    
    echo ""
    echo "🏢 Work Git Configuration:"
    read -p "Work name (for git commits): " input_work_name
    read -p "Work email: " input_work_email
    
    if [[ -n "$input_work_name" || -n "$input_work_email" ]]; then
        echo "dummy" | pass insert -m git/work >/dev/null 2>&1
        
        if [[ -n "$input_work_name" ]]; then
            echo "$input_work_name" | pass insert -m git/work/name >/dev/null 2>&1
            echo -e "${GREEN}✅ Work name set: $input_work_name${NC}"
        fi
        
        if [[ -n "$input_work_email" ]]; then
            echo "$input_work_email" | pass insert -m git/work/email >/dev/null 2>&1
            echo -e "${GREEN}✅ Work email set: $input_work_email${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}🎉 Pass setup complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Run 'update-git-secrets' to update your git configuration"
echo "2. Your credentials are now stored securely in ~/.password-store"
echo "3. You can view them with: pass show git/personal/name"
echo "4. You can edit them with: pass edit git/personal/email"
echo ""
echo "📝 Available entries:"
pass show 2>/dev/null | grep "^git/" || echo "  (No git entries created yet)"

exit 0
