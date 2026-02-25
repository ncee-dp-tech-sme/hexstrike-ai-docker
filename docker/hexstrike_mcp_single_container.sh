#!/bin/bash
set -Eeuo pipefail

# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
# echo $SCRIPT_DIR
# cd $SCRIPT_DIR

# create host-side folders used by docker-compose bind mounts
mkdir -p \
  "../logs" \
  "../data/nuclei-templates" \
  "../data/trivy" \  

[ -f "../logs/hexstrike.log" ] || touch "../logs/hexstrike.log"
chmod 0755 ../logs/hexstrike.log

podman run -d -p 8888:8888 \
  --name hexstrike-mcp-server_v2 \
  --network bridge \
  --platform linux/arm64 \
  --privileged \
  -v $(pwd)/logs/hexstrike.log:/opt/hexstrike/hexstrike.log:rw \
  -v $(pwd)/data/trivy:/root/.cache/trivy:rw \
  -v $(pwd)/data/nuclei-templates:/root/nuclei-templates:rw \
  ghcr.io/ncee-dp-tech-sme/hexstrike-ai-docker:05d8d5487d580d1a8d6c5a007eea8bd84de3b6d1