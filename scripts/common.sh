#!/bin/bash

# Common validation functions and variables for devcontainer scripts
# This file should be sourced by other scripts

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Valid values arrays
VALID_TEAMS=("ml" "cmpl" "simul" "rt" "system")
VALID_POD_VERSIONS=("cpu" "fpga" "gpu" "hybrid")
VALID_PROJECT_NAMES=("aida" "bertha")
VALID_CUDA_VERSIONS=("cpu" "cu126")
VALID_PYTHON_VERSIONS=("3.9" "3.10" "3.11" "3.12")
VALID_SHELLS=("bash" "zsh")

# Function to check if a value is in an array
_is_in_array() {
    local value="$1"
    shift
    local arr=("$@")
    for item in "${arr[@]}"; do
        if [[ "$item" == "$value" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to validate team name
validate_team_name() {
    local team_name="$1"
    
    if _is_in_array "$team_name" "${VALID_TEAMS[@]}"; then
        echo -e "${GREEN}✓ Team '$team_name' is valid${NC}"
        return 0
    fi
    
    echo -e "${RED}Error: Unknown team '$team_name'${NC}"
    echo -e "${YELLOW}Available teams: ${VALID_TEAMS[*]}${NC}"
    return 1
}

# Function to validate POD_VERSION
validate_pod_version() {
    local pod_version="$1"
    local project_name="$2"
    
    # First check if pod_version is in valid list
    if _is_in_array "$pod_version" "${VALID_POD_VERSIONS[@]}"; then
        # Additional validation for bertha project
        if [[ "$project_name" == "bertha" ]]; then
            if [[ "$pod_version" == "cpu" || "$pod_version" == "gpu" ]]; then
                echo -e "${GREEN}✓ POD_VERSION '$pod_version' is valid for project '$project_name'${NC}"
                return 0
            else
                echo -e "${RED}Error: POD_VERSION '$pod_version' is not allowed for project 'bertha'${NC}"
                echo -e "${YELLOW}For bertha project, only 'cpu' and 'gpu' POD_VERSION are allowed${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}✓ POD_VERSION '$pod_version' is valid${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}Error: Unknown POD_VERSION '$pod_version'${NC}"
    echo -e "${YELLOW}Available POD_VERSION options: ${VALID_POD_VERSIONS[*]}${NC}"
    return 1
}

# Function to validate PROJECT_NAME
validate_project_name() {
    local project_name="$1"
    
    if _is_in_array "$project_name" "${VALID_PROJECT_NAMES[@]}"; then
        echo -e "${GREEN}✓ PROJECT_NAME '$project_name' is valid${NC}"
        return 0
    fi
    
    echo -e "${RED}Error: Unknown PROJECT_NAME '$project_name'${NC}"
    echo -e "${YELLOW}Available PROJECT_NAME options: ${VALID_PROJECT_NAMES[*]}${NC}"
    return 1
}

# Function to validate CUDA_VERSION
validate_cuda_version() {
    local cuda_version="$1"
    local pod_version="$2"
    
    # First check if cuda_version is in valid list
    if _is_in_array "$cuda_version" "${VALID_CUDA_VERSIONS[@]}"; then
        # Additional validation based on POD_VERSION
        if [[ "$pod_version" == "cpu" || "$pod_version" == "fpga" ]]; then
            if [[ "$cuda_version" == "cpu" ]]; then
                echo -e "${GREEN}✓ CUDA_VERSION '$cuda_version' is valid for POD_VERSION '$pod_version'${NC}"
                return 0
            else
                echo -e "${RED}Error: CUDA_VERSION '$cuda_version' is not allowed for POD_VERSION '$pod_version'${NC}"
                echo -e "${YELLOW}For POD_VERSION '$pod_version', only 'cpu' CUDA_VERSION is allowed${NC}"
                return 1
            fi
        elif [[ "$pod_version" == "gpu" || "$pod_version" == "hybrid" ]]; then
            if [[ "$cuda_version" == "cu126" ]]; then
                echo -e "${GREEN}✓ CUDA_VERSION '$cuda_version' is valid for POD_VERSION '$pod_version'${NC}"
                return 0
            else
                echo -e "${RED}Error: CUDA_VERSION '$cuda_version' is not allowed for POD_VERSION '$pod_version'${NC}"
                echo -e "${YELLOW}For POD_VERSION '$pod_version', only 'cu126' CUDA_VERSION is allowed${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}✓ CUDA_VERSION '$cuda_version' is valid${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}Error: Unknown CUDA_VERSION '$cuda_version'${NC}"
    echo -e "${YELLOW}Available CUDA_VERSION options: ${VALID_CUDA_VERSIONS[*]}${NC}"
    return 1
}

# Function to validate PYTHON_VERSION
validate_python_version() {
    local python_version="$1"
    
    if _is_in_array "$python_version" "${VALID_PYTHON_VERSIONS[@]}"; then
        echo -e "${GREEN}✓ PYTHON_VERSION '$python_version' is valid${NC}"
        return 0
    fi
    
    echo -e "${RED}Error: Unknown PYTHON_VERSION '$python_version'${NC}"
    echo -e "${YELLOW}Available PYTHON_VERSION options: ${VALID_PYTHON_VERSIONS[*]}${NC}"
    return 1
}

# Function to validate SHELL_IN_CONTAINER
validate_shell() {
    local shell="$1"
    
    if _is_in_array "$shell" "${VALID_SHELLS[@]}"; then
        echo -e "${GREEN}✓ SHELL_IN_CONTAINER '$shell' is valid${NC}"
        return 0
    fi
    
    echo -e "${RED}Error: Unknown SHELL_IN_CONTAINER '$shell'${NC}"
    echo -e "${YELLOW}Available SHELL_IN_CONTAINER options: ${VALID_SHELLS[*]}${NC}"
    return 1
}

# Function to validate POD_VERSION and resource numbers
validate_pod_resources() {
    local pod_version="$1"
    local gpu_num="$2"
    local fpga_num="$3"
    
    # Validate GPU_NUM
    if [[ "$gpu_num" -lt 0 || "$gpu_num" -gt 2 ]]; then
        echo -e "${RED}Error: GPU_NUM must be between 0 and 2${NC}"
        return 1
    fi
    
    # Validate FPGA_NUM
    if [[ "$fpga_num" -lt 0 || "$fpga_num" -gt 8 ]]; then
        echo -e "${RED}Error: FPGA_NUM must be between 0 and 8${NC}"
        return 1
    fi
    
    # Validate resource requirements based on POD_VERSION
    if [[ "$pod_version" == "cpu" ]]; then
        if [[ "$gpu_num" -gt 0 || "$fpga_num" -gt 0 ]]; then
            echo -e "${RED}Error: CPU POD_VERSION cannot request GPU or FPGA resources${NC}"
            echo -e "${YELLOW}For CPU POD_VERSION, GPU_NUM and FPGA_NUM must be 0${NC}"
            return 1
        fi
    elif [[ "$pod_version" == "fpga" ]]; then
        if [[ "$gpu_num" -gt 0 ]]; then
            echo -e "${RED}Error: FPGA POD_VERSION cannot request GPU resources${NC}"
            echo -e "${YELLOW}For FPGA POD_VERSION, GPU_NUM must be 0${NC}"
            return 1
        fi
        if [[ "$fpga_num" -eq 0 ]]; then
            echo -e "${RED}Error: FPGA POD_VERSION must request at least 1 FPGA${NC}"
            echo -e "${YELLOW}For FPGA POD_VERSION, FPGA_NUM must be greater than 0${NC}"
            return 1
        fi
    elif [[ "$pod_version" == "gpu" ]]; then
        if [[ "$fpga_num" -gt 0 ]]; then
            echo -e "${RED}Error: GPU POD_VERSION cannot request FPGA resources${NC}"
            echo -e "${YELLOW}For GPU POD_VERSION, FPGA_NUM must be 0${NC}"
            return 1
        fi
        if [[ "$gpu_num" -eq 0 ]]; then
            echo -e "${RED}Error: GPU POD_VERSION must request at least 1 GPU${NC}"
            echo -e "${YELLOW}For GPU POD_VERSION, GPU_NUM must be greater than 0${NC}"
            return 1
        fi
    elif [[ "$pod_version" == "hybrid" ]]; then
        if [[ "$gpu_num" -eq 0 || "$fpga_num" -eq 0 ]]; then
            echo -e "${RED}Error: HYBRID POD_VERSION must request at least 1 GPU and 1 FPGA${NC}"
            echo -e "${YELLOW}For HYBRID POD_VERSION, GPU_NUM and FPGA_NUM must be greater than 0${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✓ Resource requirements are valid for POD_VERSION '$pod_version'${NC}"
    return 0
}

# Function to validate required parameters
validate_required_param() {
    local param_name="$1"
    local param_value="$2"
    
    if [[ -z "$param_value" ]]; then
        echo -e "${RED}Error: $param_name is required${NC}"
        return 1
    fi
    return 0
}

# Function to trim whitespace from a string
trim_whitespace() {
    local input="$1"
    # Remove leading and trailing whitespace
    echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Function to read and trim value from file
read_and_trim_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        cat "$file_path" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    else
        echo ""
    fi
}

# Function to show common usage pattern
show_common_usage() {
    local script_name="$1"
    local additional_options="$2"
    
    echo "Usage: $script_name --user-name <user_name> --team-name <team_name> $additional_options"
    echo ""
    echo "Options:"
    echo "  --user-name <user_name>    User name (required)"
    echo "  --team-name <team_name>    Team name (required)"
    if [[ -n "$additional_options" ]]; then
        echo "$additional_options"
    fi
    echo ""
    echo "Example:"
    echo "  $script_name --user-name younghoon --team-name ml"
    exit 1
}
