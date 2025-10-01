#!/bin/bash
# ==============================================================================
# File: build-docker-image.sh
# Description: Script to build the Docker image for Hexstrike AI.

set -Eeuo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR/..

# Use --no-cache to avoid using cached layers and ensure a consistent build
# Use --pull to always attempt to pull a newer version of the base image if available
docker build --pull -t hexstrike-ai:v6.0 -f docker/Dockerfile .
