#!/bin/bash

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Define valid options as arrays
VALID_CUDA_VERSIONS=("cpu" "cu126")
VALID_PROJECT_NAMES=("aida" "bertha")
VALID_PYTHON_VERSIONS=("3.9" "3.10" "3.11" "3.12")
VALID_SHELLS=("bash" "zsh")

CUDA_VERSION=$(trim_whitespace "$1") # cpu, cu126
PROJECT_NAME=$(trim_whitespace "$2") # base, aida, bertha
PYTHON_VERSION=$(trim_whitespace "${3:-3.10}") # 3.9, 3.10, 3.11, 3.12
file_dir=$(realpath $0)
# Set working directory (default: parent directory of HyperDex-Transformers)
WORK_DIR=$(trim_whitespace "${4:-$(dirname $(dirname $(dirname ${file_dir})))}")
SHELL_IN_CONTAINER=$(trim_whitespace "${5:-`basename $SHELL`}") # zsh, bash
CONTAINER_NAME_POSTFIX=$(trim_whitespace "${6:-""}")

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

help() {
    echo -e "${GREEN}Usage: $0 [CUDA_VERSION] [PROJECT_NAME] [PYTHON_VERSION] [WORK_DIR]"
    echo -e "CUDA_VERSION: ${VALID_CUDA_VERSIONS[*]}"
    echo -e "PROJECT_NAME: ${VALID_PROJECT_NAMES[*]} (bertha is only for CPU)"
    echo -e "PYTHON_VERSION: ${VALID_PYTHON_VERSIONS[*]}"
    echo -e "SHELL_IN_CONTAINER: ${VALID_SHELLS[*]}. default is `basename $SHELL`"
    echo -e "WORK_DIR: Working directory inside the container (default: parent directory of HyperDex-Transformers)"
    echo -e "Example: $0 cu126 aida 3.10 /home/user_name/${NC}"
    echo -e "${YELLOW}If you want to run HyperDex_Transformers tests, you need to set HF_TOKEN as an environment variable."
    echo -e "Example: export HF_TOKEN=your_api_key && $0 cu126 aida 3.10 /home/user_name/${NC}"
    exit 1
}

# Helper function to check if value is in array
contains_element() {
    local value="$1"
    shift
    local array=("$@")
    for element in "${array[@]}"; do
        if [[ "$element" == "$value" ]]; then
            return 0
        fi
    done
    return 1
}

validate_inputs() {
    local has_error=false
    local error_messages=""

    # Validate HF_TOKEN or HUGGINGFACE_API_KEY
    if [[ -z "${HF_TOKEN}" ]] && [[ -z "${HUGGINGFACE_API_KEY}" ]]; then
        error_messages+="${YELLOW}Warning: Neither HF_TOKEN nor HUGGINGFACE_API_KEY is set. Some features may not work properly.${NC}\n"
    fi

    # Validate PROJECT_NAME
    if ! contains_element "${PROJECT_NAME}" "${VALID_PROJECT_NAMES[@]}"; then
        error_messages+="${RED}Error: PROJECT_NAME must be one of: ${VALID_PROJECT_NAMES[*]}${NC}\n"
        has_error=true
    fi

    # Validate CUDA_VERSION
    if [[ "${PROJECT_NAME}" == "bertha" ]]; then
        if [[ "${CUDA_VERSION}" != "cpu" ]]; then
            error_messages+="${RED}Error: For PROJECT_NAME 'bertha', only CUDA_VERSION 'cpu' is allowed${NC}\n"
            has_error=true
        fi
    elif ! contains_element "${CUDA_VERSION}" "${VALID_CUDA_VERSIONS[@]}"; then
        error_messages+="${RED}Error: For PROJECT_NAME 'aida', CUDA_VERSION must be one of: ${VALID_CUDA_VERSIONS[*]}${NC}\n"
        has_error=true
    fi

    # Validate SHELL_IN_CONTAINER
    if ! contains_element "${SHELL_IN_CONTAINER}" "${VALID_SHELLS[@]}"; then
        error_messages+="${RED}Error: SHELL_IN_CONTAINER must be one of: ${VALID_SHELLS[*]}${NC}\n"
        has_error=true
    fi

    # Validate PYTHON_VERSION
    if ! contains_element "${PYTHON_VERSION}" "${VALID_PYTHON_VERSIONS[@]}"; then
        error_messages+="${RED}Error: PYTHON_VERSION must be one of: ${VALID_PYTHON_VERSIONS[*]}${NC}\n"
        has_error=true
    fi

    # If any validation failed, print all error messages and show help
    if [ "$has_error" = true ]; then
        echo -e "${error_messages}"
        help
    fi
}

if [ -z "$CUDA_VERSION" ] || [ "$CUDA_VERSION" == "--help" ] || [ "$CUDA_VERSION" == "-h" ]; then
    help
fi

check_repo_version() {
    # Fetch the latest changes from the origin
    git fetch origin

    # Get the current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Check for differences
    diff_output=$(git diff HEAD origin/$current_branch)

    if [ -n "$diff_output" ]; then
        echo "There are differences between the local branch and the remote branch."
        echo "Differences:"
        echo "$diff_output"

        # Ask the user if they want to pull
        read -p "Do you want to pull the remote changes? (y/n): " answer
        if [ "$answer" == "y" ]; then
            git pull origin $current_branch
        else
            echo "Pull cancelled."
        fi
    else
        echo "There are no differences between the local branch and the remote branch."
    fi
}

check_repo_version

validate_inputs

DOCKER_VERSION=$(read_and_trim_file "dockerfiles/ecr_version/${PROJECT_NAME}_version")
IMAGE_NAME="devcontainer-${PROJECT_NAME}"
IMAGE_TAG="${CUDA_VERSION}-${DOCKER_VERSION}"

echo -e "${GREEN}WORK_DIR: ${WORK_DIR}${NC}"
# Generate random ID
RANDOM_ID=$(uuidgen | tr -dc 'a-zA-Z0-9' | head -c 5)
USER=`whoami`
USER_ID=$(id -u ${USER})
GROUP_ID=$(id -g ${USER})
USER_NAME=${USER}
GROUP_NAME="hyperaccel"

DOCKER_RUN_CMD="run -it --rm \
    --name ${IMAGE_NAME}-${IMAGE_TAG}-${USER}-${CONTAINER_NAME_POSTFIX}-${RANDOM_ID}"

if [[ "${CUDA_VERSION}" == cu* ]]; then
    DOCKER_RUN_CMD+="\
     --gpus=all \
     -e CUDA_VERSION=${CUDA_VERSION}"
fi

# SSH 키 경로 설정
SSH_PATH="${HOME}/.ssh"
# For ROME server, SSH key is in /etc/ssh/rsa/${USER}
if [[ ! -f "${SSH_PATH}/id_rsa" ]] && [[ ! -f "${SSH_PATH}/id_ed25519" ]]; then
    SSH_PATH="/etc/ssh/rsa/${USER}"
fi

# HF_HOME 설정
if [[ -d "/shared/huggingface" ]]; then
    DOCKER_RUN_CMD+="\
    -v /shared/huggingface:/shared/huggingface \
    -e HF_HOME=/shared/huggingface"
fi

if [[ "${PROJECT_NAME}" == "aida" ]]; then
    # AIDA 프로젝트에서는 /tmp/hyperdex 디렉토리를 마운트
    if [[ ! -d "/tmp/hyperdex" ]]; then
        mkdir -p /tmp/hyperdex
        chmod 775 -R /tmp/hyperdex
    fi
    DOCKER_RUN_CMD+="\
    -v /tmp/hyperdex:/tmp/hyperdex"
fi

DOCKER_RUN_CMD+="\
    --network host \
    --privileged \
    -v ${WORK_DIR}:/workspace/dev \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -v /etc/shadow:/etc/shadow:ro \
    -v ${HOME}/.cache:/tmp/user/.cache \
    -v ${HOME}/.gitconfig:/tmp/user/.gitconfig \
    -v ${SSH_PATH}:/tmp/user/.ssh \
    -v ${HOME}/.zsh_history:/tmp/user/.zsh_history \
    -v ${HOME}/.bash_history:/tmp/user/.bash_history \
    -e HF_TOKEN=${HF_TOKEN} \
    -e HUGGINGFACE_API_KEY=${HUGGINGFACE_API_KEY} \
    -e HOME=${HOME} \
    -e USER_ID=${USER_ID} \
    -e GROUP_ID=${GROUP_ID} \
    -e USER_NAME=${USER_NAME} \
    -e GROUP_NAME=${GROUP_NAME} \
    -e PYTHON_VERSION=${PYTHON_VERSION} \
    -e SHELL_IN_CONTAINER=${SHELL_IN_CONTAINER} \
    -u ${USER_ID}:${GROUP_ID}"

# If ~/.p10k.zsh exists, mount it
if [[ -f ${HOME}/.p10k.zsh ]]; then
    DOCKER_RUN_CMD+=" -v ${HOME}/.p10k.zsh:/tmp/user/.p10k.zsh"
fi
# If ~/.vim exists, mount it
if [[ -d ${HOME}/.vim ]]; then
    DOCKER_RUN_CMD+=" -v ${HOME}/.vim:/tmp/user/.vim"
fi
# If ~/.vimrc exists, mount it
if [[ -f ${HOME}/.vimrc ]]; then
    DOCKER_RUN_CMD+=" -v ${HOME}/.vimrc:/tmp/user/.vimrc"
fi

# Add additional docker run command
if [[ -f $(dirname ${file_dir})/additional_docker_run_cmd ]]; then
    # Use eval echo to expand environment variables
    ADDITIONAL_DOCKER_RUN_CMD=$(eval echo "$(cat $(dirname ${file_dir})/additional_docker_run_cmd)")
    DOCKER_RUN_CMD+=" ${ADDITIONAL_DOCKER_RUN_CMD}"
fi

echo -e "${GREEN}DOCKER_RUN_CMD: ${DOCKER_RUN_CMD}${NC}"

docker ${DOCKER_RUN_CMD} \
    637423205005.dkr.ecr.us-east-1.amazonaws.com/hyperaccel/${IMAGE_NAME}:${IMAGE_TAG} /bin/$SHELL_IN_CONTAINER