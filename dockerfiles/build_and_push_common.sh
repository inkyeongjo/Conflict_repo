#!/bin/bash

# Error handling and debugging settings
set -euo pipefail  # u: error if undeclared variable is used
set -x             # print executed commands

# script file path
SCRIPT_DIR=$(dirname $(realpath $0))

# Change current directory
cd ${SCRIPT_DIR}

# Parse parameters
ARCH=${1:-cpu}
CUDA_VERSION=${2:-cu126}
PROJECT_NAME=${3:-base}

# Validate ARCH
if [[ ! "${ARCH}" =~ ^(cpu|gpu)$ ]]; then
    echo "Error: ARCH must be one of: cpu, gpu"
    exit 1
fi

# Validate CUDA_VERSION
if [[ ! "${CUDA_VERSION}" =~ ^(cu126)$ ]]; then
    echo "Error: CUDA_VERSION must be one of: cu126"
    exit 1
fi

# Validate PROJECT_NAME by checking if directory exists
if [[ ! -d "${SCRIPT_DIR}/${PROJECT_NAME}" ]]; then
    echo "Error: Project directory '${PROJECT_NAME}' does not exist in ${SCRIPT_DIR}"
    echo "Available projects:"
    ls -d ${SCRIPT_DIR}/*/ | xargs -n 1 basename
    exit 1
fi

# Activate BuildKit
export DOCKER_BUILDKIT=1

# Read DOCKER_VERSION and remove whitespace
DOCKER_VERSION=$(cat ${SCRIPT_DIR}/${PROJECT_NAME}_version | tr -d '[:space:]')

# Calculate CUDA_FULL_VERSION
full_version=${CUDA_VERSION/cu/}
if [[ ${ARCH} == "cpu" ]]; then
    CUDA_FULL_VERSION="cpu"
    IMAGE_TAG="${ARCH}-${DOCKER_VERSION}"
else
    CUDA_FULL_VERSION="${full_version:0:2}.${full_version:2:1}.0"
    IMAGE_TAG="${CUDA_VERSION}-${DOCKER_VERSION}"
fi

# Construct image names
LOCAL_IMAGE="hyperaccel/devcontainer-${PROJECT_NAME}:${IMAGE_TAG}"
HARBOR_IMAGE="cr.hyperaccel.net/hyperaccel/devcontainer-${PROJECT_NAME}:${IMAGE_TAG}"

# Export variables for use in calling scripts
export ARCH
export CUDA_VERSION
export PROJECT_NAME
export CUDA_FULL_VERSION
export DOCKER_VERSION
export IMAGE_TAG
export LOCAL_IMAGE
export HARBOR_IMAGE
export SCRIPT_DIR
