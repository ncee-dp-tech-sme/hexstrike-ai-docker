#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"

cd $SCRIPT_DIR

mkdir -p \
  "../logs" \
  "../data/trivy" \
  "../data/wpscan" \
  "../data/nuclei-templates" \
  "../data/amass" \
  "../data/msf" \
  "../data/postgres"

[ -f "../logs/hexstrike.log" ] || touch "../logs/hexstrike.log"

sudo docker-compose \
  -f "./docker-compose.yml" \
  up -d --force-recreate
