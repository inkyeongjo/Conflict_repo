#!/bin/bash
set -euo pipefail

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to show usage
usage() {
    echo "Usage: $0 --user-name <user_name> --team-name <team_name>"
    echo ""
    echo "Options:"
    echo "  --user-name <user_name>    User name (required)"
    echo "  --team-name <team_name>    Team name (required)"
    echo ""
    echo "Example:"
    echo "  $0 --user-name younghoon --team-name ml"
    exit 1
}

# Parse command line arguments
USER_NAME=""
TEAM_NAME=""
CERTIFICATE_AUTHORITY_DATA=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --user-name)
            USER_NAME=$(trim_whitespace "$2")
            shift 2
            ;;
        --team-name)
            TEAM_NAME=$(trim_whitespace "$2")
            shift 2
            ;;
        --certificate-authority-data)
            CERTIFICATE_AUTHORITY_DATA=$(trim_whitespace "$2")
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Validate required parameters
if ! validate_required_param "--user-name" "$USER_NAME"; then
    usage
fi

if ! validate_required_param "--team-name" "$TEAM_NAME"; then
    usage
fi

# Validate team name using common function
if ! validate_team_name "$TEAM_NAME"; then
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../templates/kubeconfig-template.yaml"

# Check if template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo -e "${RED}Error: Template file not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Create ~/.kube directory if it doesn't exist
KUBE_DIR="$HOME/.kube"
if [[ ! -d "$KUBE_DIR" ]]; then
    echo -e "${YELLOW}Creating ~/.kube directory...${NC}"
    mkdir -p "$KUBE_DIR"
fi

# Backup existing config if it exists
CONFIG_FILE="$KUBE_DIR/config"
if [[ -f "$CONFIG_FILE" ]]; then
    BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Backing up existing config to: $BACKUP_FILE${NC}"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

# Validate certificate authority data
if [[ -z "$CERTIFICATE_AUTHORITY_DATA" ]]; then
    echo -e "${RED}Error: CERTIFICATE_AUTHORITY_DATA is required${NC}"
    echo -e "${YELLOW}Please set CERTIFICATE_AUTHORITY_DATA in your .env file or provide it as a command line argument${NC}"
    echo -e "${YELLOW}Example:${NC}"
    echo -e "${YELLOW}  In .env file: CERTIFICATE_AUTHORITY_DATA=your_certificate_data_here${NC}"
    echo -e "${YELLOW}  Command line: $0 --user-name $USER_NAME --team-name $TEAM_NAME --certificate-authority-data your_certificate_data_here${NC}"
    exit 1
fi

# Generate kubeconfig by replacing placeholders
echo -e "${GREEN}Generating kubeconfig for user: $USER_NAME, team: $TEAM_NAME${NC}"

# Use sed to replace placeholders
sed -e "s/<USER_NAME>/$USER_NAME/g" \
    -e "s/<TEAM_NAME>/$TEAM_NAME/g" \
    -e "s|<CERTIFICATE_AUTHORITY_DATA>|$CERTIFICATE_AUTHORITY_DATA|g" \
    "$TEMPLATE_FILE" > "$CONFIG_FILE"

# Set appropriate permissions
chmod 600 "$CONFIG_FILE"

echo -e "${GREEN}✓ Kubeconfig generated successfully at: $CONFIG_FILE${NC}"
echo -e "${GREEN}✓ You can now use kubectl commands with your team namespace${NC}"
echo -e "${YELLOW}Note: You may need to run 'kubelogin get-token' to authenticate${NC}"
