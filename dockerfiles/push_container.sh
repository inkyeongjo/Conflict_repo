#!/bin/bash

# Source common functions and variables
source "$(dirname $(realpath $0))/build_and_push_common.sh"

# Check if local image exists
if ! docker images ${LOCAL_IMAGE} --format "{{.Repository}}:{{.Tag}}" | grep -q "${IMAGE_TAG}"; then
    echo "Error: Local image ${LOCAL_IMAGE} does not exist. Please build it first."
    exit 1
fi

# Harbor authentication
set +x
echo "${HARBOR_TOKEN}" | docker login cr.hyperaccel.net --username "${HARBOR_USERNAME}" --password-stdin
set -x

echo "Tagging and pushing image to Harbor..."
docker tag ${LOCAL_IMAGE} ${HARBOR_IMAGE}
docker push ${HARBOR_IMAGE}

echo "Push process completed successfully!"
