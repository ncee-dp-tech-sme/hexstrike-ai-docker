#!/bin/bash
# ==============================================================================
# File: build-docker-image.sh
# Description: Script to build the Docker image for HexStrike AI and capture logs.

set -Eeuo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/.."

LOG_FILE="${BUILD_LOG:-build.log}"

echo "[+] Building image with docker | log: ${LOG_FILE}" >&2

# Use --no-cache to avoid using cached layers and ensure a consistent build
# Use --pull to always attempt to pull a newer version of the base image if available
docker build --pull -t hexstrike-ai:v6.0 -f docker/Dockerfile . \
  2>&1 | tee "${LOG_FILE}"
