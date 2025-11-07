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

# Generate PVC name
PVC_NAME="${USER_NAME}-user-home-pvc"
NAMESPACE="hyperaccel-${TEAM_NAME}-ns"

echo -e "${GREEN}Deleting PVC: $PVC_NAME${NC}"
echo -e "${GREEN}Namespace: $NAMESPACE${NC}"

# Execute kubectl delete command
echo -e "${YELLOW}Executing: kubectl delete pvc $PVC_NAME -n $NAMESPACE${NC}"

if kubectl delete pvc "$PVC_NAME" -n "$NAMESPACE"; then
    echo -e "${GREEN}✓ Successfully deleted PVC: $PVC_NAME${NC}"
    echo -e "${GREEN}✓ Namespace: $NAMESPACE${NC}"
else
    echo -e "${RED}✗ Failed to delete PVC: $PVC_NAME${NC}"
    echo -e "${YELLOW}Note: The PVC might not exist or you might not have permission${NC}"
    exit 1
fi
