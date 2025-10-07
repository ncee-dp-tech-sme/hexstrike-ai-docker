#!/bin/bash
# ==============================================================================
# File: build-docker-image.sh
set -Eeuo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
cd "$SCRIPT_DIR/.."

LOG_FILE="${BUILD_LOG:-build.log}"
IMAGE_TAG="hexstrike-ai:v6.0"

echo "[+] Building image with docker | log: ${LOG_FILE}" >&2

# Enable BuildKit if Docker supports it; harmless if ignored.
export DOCKER_BUILDKIT=1

docker build \
  --tag "${IMAGE_TAG}" \
  --file docker/Dockerfile \
  . 2>&1 | tee "${LOG_FILE}"
