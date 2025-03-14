#!/bin/bash
# Eliza Docker Build Script
# -------------------------
# This script builds the eliza Docker image with the correct context.
# It's designed to be run from any location, and will automatically
# change to the eliza directory to ensure proper building.
#
# Usage:
#   ./build.sh [additional docker build options]
#
# Examples:
#   ./build.sh --tag eliza:dev
#   ./build.sh --tag ghcr.io/username/eliza:latest --push
#   ./build.sh --build-arg NODE_ENV=production

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to eliza directory for correct context
cd "${SCRIPT_DIR}"

# Default tag if not provided
DEFAULT_TAG="eliza:latest"

# Build the Docker image
docker build \
  -f Dockerfile \
  -t ${DOCKER_TAG:-$DEFAULT_TAG} \
  "$@" \
  . 