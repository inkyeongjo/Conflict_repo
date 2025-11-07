#!/bin/bash
set -euo pipefail

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --user-name <name>           User name (required)"
    echo "  --team-name <team>           Team name (required)"
    echo "  --project-name <project>     Project name (aida, bertha) (default: aida)"
    echo "  --cuda-version <version>     CUDA version (cpu, cu126) (default: cpu)"
    echo "  --pod-version <version>      POD version (cpu, fpga, gpu, hybrid) (default: cpu)"
    echo "  --python-version <version>   Python version (default: 3.10)"
    echo "  --shell-env <shell>          Shell environment (default: current shell)"
    echo "  --gpu-num <num>              GPU number (default: 0)"
    echo "  --fpga-num <num>             FPGA number (default: 0)"
    echo "  --container-postfix <postfix> Container name postfix (default: "")"
    echo "  --output <file>              Output YAML file path (default: k8s-deployment.yaml)"
    echo "  --apply                      Apply the generated YAML to Kubernetes"
    echo "  --dry-run                    Show what would be applied without actually applying"
    echo "  --help                       Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --user-name younghoon --team-name ml --project-name aida --cuda-version cu126 --apply"
    exit 1
}

# Default values
USER_NAME="inin"
TEAM_NAME="ml"
PROJECT_NAME="aida"
CUDA_VERSION="cpu"
POD_VERSION="cpu"
PYTHON_VERSION="3.10"
SHELL_ENV=$(basename $SHELL)
GPU_NUM="0"
FPGA_NUM="0"
CONTAINER_POSTFIX=""
OUTPUT_DIR="k8s-yaml"
OUTPUT_FILE=""
APPLY=false
DRY_RUN=false

# Parse command line arguments
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
        --project-name)
            PROJECT_NAME=$(trim_whitespace "$2")
            shift 2
            ;;
        --cuda-version)
            CUDA_VERSION=$(trim_whitespace "$2")
            shift 2
            ;;
        --pod-version)
            POD_VERSION=$(trim_whitespace "$2")
            shift 2
            ;;
        --python-version)
            PYTHON_VERSION=$(trim_whitespace "$2")
            shift 2
            ;;
        --shell-env)
            SHELL_ENV=$(trim_whitespace "$2")
            shift 2
            ;;
        --gpu-num)
            GPU_NUM=$(trim_whitespace "$2")
            shift 2
            ;;
        --fpga-num)
            FPGA_NUM=$(trim_whitespace "$2")
            shift 2
            ;;
        --container-postfix)
            CONTAINER_POSTFIX=$(trim_whitespace "$2")
            shift 2
            ;;
        --output)
            OUTPUT_FILE=$(trim_whitespace "$2")
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR=$(trim_whitespace "$2")
            shift 2
            ;;
        --apply)
            APPLY=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
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

# Validate all parameters using common functions
if ! validate_team_name "$TEAM_NAME"; then
    exit 1
fi

if ! validate_pod_version "$POD_VERSION" "$PROJECT_NAME"; then
    exit 1
fi

if ! validate_project_name "$PROJECT_NAME"; then
    exit 1
fi

if ! validate_cuda_version "$CUDA_VERSION" "$POD_VERSION"; then
    exit 1
fi

if ! validate_python_version "$PYTHON_VERSION"; then
    exit 1
fi

if ! validate_shell "$SHELL_ENV"; then
    exit 1
fi

if ! validate_pod_resources "$POD_VERSION" "$GPU_NUM" "$FPGA_NUM"; then
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$(realpath "$0")")
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# Read project version from version file
VERSION_FILE="$PROJECT_ROOT/dockerfiles/${PROJECT_NAME}_version"
if [[ -f "$VERSION_FILE" ]]; then
    PROJECT_VERSION=$(read_and_trim_file "$VERSION_FILE")
    echo -e "${GREEN}✓ Using project version: $PROJECT_VERSION${NC}"
else
    echo -e "${RED}Error: Version file not found: $VERSION_FILE${NC}"
    exit 1
fi

# Select template file based on POD_VERSION
TEMPLATE_FILE="$SCRIPT_DIR/../templates/devcontainer-template-${POD_VERSION}.yaml"

# Check if template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo -e "${RED}Error: Template file not found for POD_VERSION '$POD_VERSION': $TEMPLATE_FILE${NC}"
    echo -e "${YELLOW}Available POD_VERSION options: cpu, gpu, fpga, hybrid${NC}"
    exit 1
fi

# Create output directory if it doesn't exist
if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo -e "${YELLOW}Creating output directory: $OUTPUT_DIR${NC}"
    mkdir -p "$OUTPUT_DIR"
fi

# Generate deployment name (same as in YAML template)
if [[ -n "$CONTAINER_POSTFIX" ]]; then
    DEPLOYMENT_NAME="${USER_NAME}-${PROJECT_NAME}-${CUDA_VERSION}-${POD_VERSION}-${CONTAINER_POSTFIX#-}"
else
    DEPLOYMENT_NAME="${USER_NAME}-${PROJECT_NAME}-${CUDA_VERSION}-${POD_VERSION}"
fi

# Set default output file if not specified
if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="$OUTPUT_DIR/${DEPLOYMENT_NAME}.yaml"
fi

echo -e "${GREEN}Generating Kubernetes YAML with the following parameters:${NC}"
echo -e "  User Name: $USER_NAME"
echo -e "  Team Name: $TEAM_NAME"
echo -e "  Project Name: $PROJECT_NAME"
echo -e "  Project Version: $PROJECT_VERSION"
echo -e "  CUDA Version: $CUDA_VERSION"
echo -e "  POD Version: $POD_VERSION"
echo -e "  Python Version: $PYTHON_VERSION"
echo -e "  Shell Environment: $SHELL_ENV"
echo -e "  GPU Number: $GPU_NUM"
echo -e "  FPGA Number: $FPGA_NUM"
echo -e "  Container Postfix: $CONTAINER_POSTFIX"
echo -e "  Deployment Name: $DEPLOYMENT_NAME"
echo -e "  Template File: $(basename $TEMPLATE_FILE)"
echo -e "  Output Directory: $OUTPUT_DIR"
echo -e "  Output File: $OUTPUT_FILE"
echo ""

# Function to generate YAML file with placeholder replacement
generate_yaml_file() {
    local input_file="$1"
    local output_file="$2"
    
    sed -e "s/<USER_NAME>/$USER_NAME/g" \
        -e "s/<TEAM_NAME>/$TEAM_NAME/g" \
        -e "s/<PROJECT_NAME>/$PROJECT_NAME/g" \
        -e "s/<PROJECT_VERSION>/$PROJECT_VERSION/g" \
        -e "s/<CUDA_VERSION>/$CUDA_VERSION/g" \
        -e "s/<POD_VERSION>/$POD_VERSION/g" \
        -e "s/<PYTHON_VERSION>/$PYTHON_VERSION/g" \
        -e "s/<SHELL_ENV>/$SHELL_ENV/g" \
        -e "s/<GPU_NUM>/$GPU_NUM/g" \
        -e "s/<FPGA_NUM>/$FPGA_NUM/g" \
        -e "s/<CONTAINER_POSTFIX>/$([ -n "$CONTAINER_POSTFIX" ] && echo "-${CONTAINER_POSTFIX#-}" || echo "")/g" \
        "$input_file" > "$output_file"
}

# Generate the YAML file by replacing placeholders
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Dry run mode: Creating temporary file for validation${NC}"
    # Create a temporary file for dry-run validation
    TEMP_FILE=$(mktemp)
    generate_yaml_file "$TEMPLATE_FILE" "$TEMP_FILE"
    if [[ $? -eq 0 ]]; then
        OUTPUT_FILE="$TEMP_FILE"
    else
        echo -e "${RED}✗ Failed to generate temporary YAML file${NC}"
        exit 1
    fi
else
    generate_yaml_file "$TEMPLATE_FILE" "$OUTPUT_FILE"
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ YAML file generated successfully: $OUTPUT_FILE${NC}"
    else
        echo -e "${RED}✗ Failed to generate YAML file${NC}"
        exit 1
    fi
fi

# Apply to Kubernetes if requested
if [[ "$APPLY" == true && "$DRY_RUN" != true ]]; then
    echo -e "${YELLOW}Applying YAML to Kubernetes...${NC}"
    if kubectl apply -f "$OUTPUT_FILE"; then
        echo -e "${GREEN}✓ Successfully applied YAML to Kubernetes${NC}"
        echo -e "${GREEN}Deployment name: $DEPLOYMENT_NAME${NC}"
        echo -e "${GREEN}Namespace: hyperaccel-$TEAM_NAME-ns${NC}"
    else
        echo -e "${RED}✗ Failed to apply YAML to Kubernetes${NC}"
        exit 1
    fi
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Dry run mode - showing what would be applied:${NC}"
    kubectl apply -f "$OUTPUT_FILE" --dry-run=client
    # Clean up temporary file
    if [[ "$OUTPUT_FILE" == /tmp/* ]]; then
        rm -f "$OUTPUT_FILE"
        echo -e "${YELLOW}Temporary file cleaned up${NC}"
    fi
fi

echo -e "${GREEN}Done!${NC}"
