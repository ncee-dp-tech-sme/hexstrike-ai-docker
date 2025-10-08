#!/bin/bash

set -Eeuo pipefail

# Create directory logs for volume mount if it doesn't exist
mkdir -p "$(pwd)/logs"

docker run \
    --rm \
    --cap-add=NET_RAW \
    --cap-add=NET_ADMIN \
    -p 8888:8888 \
    -v "$(pwd)/logs:/opt/hexstrike/logs:Z" \
    hexstrike-ai:v6.0
