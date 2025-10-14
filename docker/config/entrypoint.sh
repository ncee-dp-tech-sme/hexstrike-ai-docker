#!/usr/bin/env bash
# HexStrike MCP minimal entrypoint
# - Start server immediately
# - Background update of security databases (best-effort)

set -euo pipefail

# Run background updater (logs go to container stdout/stderr)
{ /usr/local/bin/update-tools-databases.sh; } &

# Start HexStrike MCP server
exec /opt/hexstrike/venv/bin/gunicorn \
  --bind 0.0.0.0:8888 \
  --workers 2 \
  --threads 8 \
  --timeout 3600 \
  --graceful-timeout 120 \
  --keep-alive 60 \
  "hexstrike_server:app"
