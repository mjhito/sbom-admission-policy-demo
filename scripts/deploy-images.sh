#!/usr/bin/env bash

set -eou pipefail

# Function to print the usage information and exit the script with a non-zero status
function print_usage {
    echo "Usage: bash deploy-images.sh"
    echo "$*"
    exit 1
}

# Build and push images
docker build -t "$REGISTRY"/"$IMAGE_TAG" . --push

TODO
# Attach SBOM to the image
# ./sbom-attach/bin --sbom="$SBOM_FILE" \
#     --registry="$REGISTRY" \
#     --registry-username="$REGISTRY_USERNAME" \
#     --registry-password="$REGISTRY_PASSWORD" \
#     --image-tag="$IMAGE_TAG"