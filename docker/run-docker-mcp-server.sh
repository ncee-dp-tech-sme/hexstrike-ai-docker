#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
cd "$SCRIPT_DIR/.."

touch ./logs/hexstrike.log

docker run \
    --rm \
    --name hexstrike-mcp-server \
    --cap-add=NET_RAW \
    --cap-add=NET_ADMIN \
    -p 8888:8888 \
    -v "$SCRIPT_DIR/logs/hexstrike.log:/opt/hexstrike/hexstrike.log:rw,Z" \
    hexstrike-ai:v6.0
