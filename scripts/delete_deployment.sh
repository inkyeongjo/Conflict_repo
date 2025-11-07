#!/bin/bash
set -euo pipefail

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to show usage
usage() {
    echo "Usage: $0 --user-name <user_name> --team-name <team_name> --project-name <project_name> --cuda-version <cuda_version> --pod-version <pod_version> [--container-postfix <postfix>]"
    echo ""
    echo "Options:"
    echo "  --user-name <user_name>        User name (required)"
    echo "  --team-name <team_name>        Team name (required)"
    echo "  --project-name <project_name>  Project name (required)"
    echo "  --cuda-version <cuda_version>  CUDA version (required)"
    echo "  --pod-version <pod_version>    POD version (required)"
    echo "  --container-postfix <postfix>  Container postfix (optional)"
    echo ""
    echo "Example:"
    echo "  $0 --user-name younghoon --team-name ml --project-name aida --cuda-version cu126 --pod-version gpu"
    echo "  $0 --user-name younghoon --team-name ml --project-name aida --cuda-version cu126 --pod-version gpu --container-postfix test-gpu"
    exit 1
}

# Parse command line arguments
USER_NAME=""
TEAM_NAME=""
PROJECT_NAME=""
CUDA_VERSION=""
POD_VERSION=""
CONTAINER_POSTFIX=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --user-name)
            USER_NAME="$2"
            shift 2
            ;;
        --team-name)
            TEAM_NAME="$2"
            shift 2
            ;;
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --cuda-version)
            CUDA_VERSION="$2"
            shift 2
            ;;
        --pod-version)
            POD_VERSION="$2"
            shift 2
            ;;
        --container-postfix)
            CONTAINER_POSTFIX="$2"
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

if ! validate_required_param "--project-name" "$PROJECT_NAME"; then
    usage
fi

if ! validate_required_param "--cuda-version" "$CUDA_VERSION"; then
    usage
fi

if ! validate_required_param "--pod-version" "$POD_VERSION"; then
    usage
fi

# Validate team name using common function
if ! validate_team_name "$TEAM_NAME"; then
    exit 1
fi

# Generate deployment name based on CONTAINER_POSTFIX
if [[ -n "$CONTAINER_POSTFIX" ]]; then
    DEPLOYMENT_NAME="${USER_NAME}-${PROJECT_NAME}-${CUDA_VERSION}-${POD_VERSION}-${CONTAINER_POSTFIX#-}"
    echo -e "${GREEN}Deleting deployment with postfix: $DEPLOYMENT_NAME${NC}"
else
    DEPLOYMENT_NAME="${USER_NAME}-${PROJECT_NAME}-${CUDA_VERSION}-${POD_VERSION}"
    echo -e "${GREEN}Deleting deployment without postfix: $DEPLOYMENT_NAME${NC}"
fi

# Execute kubectl delete command
NAMESPACE="hyperaccel-${TEAM_NAME}-ns"
echo -e "${YELLOW}Executing: kubectl delete deployment $DEPLOYMENT_NAME -n $NAMESPACE${NC}"

if kubectl delete deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"; then
    echo -e "${GREEN}✓ Successfully deleted deployment: $DEPLOYMENT_NAME${NC}"
    echo -e "${GREEN}✓ Namespace: $NAMESPACE${NC}"
else
    echo -e "${RED}✗ Failed to delete deployment: $DEPLOYMENT_NAME${NC}"
    echo -e "${YELLOW}Note: The deployment might not exist or you might not have permission${NC}"
    exit 1
fi
