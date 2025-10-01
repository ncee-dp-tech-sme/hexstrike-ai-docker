#!/bin/bash

set -Eeuo pipefail

# Default to Docker unless caller provides an alternative runtime (e.g. podman)
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-docker}"

# Create directories for volume mounts if they don't exist
mkdir -p "$(pwd)/scan-results"
mkdir -p "$(pwd)/logs"

"${CONTAINER_RUNTIME}" run \
    --detach \
    --name hexstrike-mcp \
    --restart unless-stopped \
    --cap-add=NET_RAW \
    --cap-add=NET_ADMIN \
    -p 8888:8888 \
    -v "$(pwd)/scan-results:/opt/hexstrike/results:Z" \
    -v "$(pwd)/logs:/opt/hexstrike/logs:Z" \
    hexstrike-ai:v6.0

echo "HexStrike MCP server is running in detached mode (container: hexstrike-mcp)."
echo "View logs with: ${CONTAINER_RUNTIME} logs -f hexstrike-mcp"
