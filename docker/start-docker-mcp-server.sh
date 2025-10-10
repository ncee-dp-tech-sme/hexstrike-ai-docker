#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"

touch $SCRIPT_DIR/../logs/hexstrike.log

sudo docker-compose \
    -f $SCRIPT_DIR/docker-compose.yml \
    up -d --force-recreate
