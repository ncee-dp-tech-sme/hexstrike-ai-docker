#!/usr/bin/env bash
# HexStrike MCP minimal entrypoint
# - Start server immediately
# - Background update of security databases (best-effort)

set -euo pipefail

# --- Metasploit DB bootstrap (one-time, idempotent) ---
# Behavior:
# - If MSF_DB_URL is empty or unset, skip DB bootstrap.
# - If an active DB connection is already configured (db_status), skip bootstrap.
# - Otherwise, connect once and persist settings via db_save (stored under /root/.msf4).
if [ -z "${MSF_DB_URL:-}" ]; then
  echo "[msf] MSF_DB_URL is not set; skipping Metasploit DB bootstrap."
else
  echo "[msf] Checking current Metasploit DB status…"
  if msfconsole -qx 'db_status; exit -y' | grep -q 'Connected to'; then
    echo "[msf] A data service is already configured; skipping bootstrap."
  else
    echo "[msf] Initializing Metasploit DB config via db_connect…"
    mkdir -p /root/.msf4
    if msfconsole -qx "db_connect ${MSF_DB_URL}; db_save; db_status; exit -y"; then
      echo "[msf] Metasploit DB configured and persisted."
    else
      echo "[msf] db_connect failed; leaving Metasploit unconfigured."
    fi
  fi
fi

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
