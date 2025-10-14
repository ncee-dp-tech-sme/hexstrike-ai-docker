#!/usr/bin/env bash
# HexStrike MCP minimal entrypoint (best practice)
# - Start server immediately
# - Fire-and-forget background prewarm of tool caches (best effort)
# - Tiny per-tool locks to avoid concurrent writes

set -euo pipefail

# Kick background security DBs update (don’t block server startup).
# Logs go to the container stdout/stderr.
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
