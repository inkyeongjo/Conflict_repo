#!/bin/bash

# Source common functions and variables
source "$(dirname $(realpath $0))/build_and_push_common.sh"

echo "Building image ${LOCAL_IMAGE}..."

if [[ ${ARCH} == "cpu" ]]; then
    build_args="--build-arg CUDA_FULL_VERSION=${CUDA_FULL_VERSION} --build-arg CUDA_VERSION=${ARCH}"
else
    build_args="--build-arg CUDA_FULL_VERSION=${CUDA_FULL_VERSION} --build-arg CUDA_VERSION=${CUDA_VERSION}"
fi

if [[ ${PROJECT_NAME} != "base" ]]; then
    base_version=$(cat ${SCRIPT_DIR}/base_version)
    build_args="${build_args} --build-arg BASE_DOCKER_VERSION=${base_version}"
fi

docker build -f ./${PROJECT_NAME}/Dockerfile -t ${LOCAL_IMAGE} ${build_args} .

echo "Build process completed successfully!"
