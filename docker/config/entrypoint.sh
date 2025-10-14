#!/usr/bin/env bash
# HexStrike MCP minimal entrypoint (best practice)
# - Start server immediately
# - Fire-and-forget background prewarm of tool caches (best effort)
# - Tiny per-tool locks to avoid concurrent writes

set -euo pipefail

# Persistent paths (mounted via docker-compose)
CACHE_WPSCAN_DB="${HOME}/.cache/wpscan/db"
CACHE_TRIVY="${HOME}/.cache/trivy"
CONF_AMASS="${HOME}/.config/amass"
NUCLEI_TEMPLATES="${HOME}/nuclei-templates"

# Internal maintenance dir
MAINT_DIR="/opt/hexstrike/maintenance"
LOCK_DIR="${MAINT_DIR}/locks"
LOGFILE="${MAINT_DIR}/updates.log"

mkdir -p "$CACHE_WPSCAN_DB" "$CACHE_TRIVY" "$CONF_AMASS" "$NUCLEI_TEMPLATES" \
         "$LOCK_DIR" "$MAINT_DIR" || true
touch "$LOGFILE" || true

# Minimal lock using a directory (portable without flock)
_lock() {
  # $1: lock name
  local name="$1" path="${LOCK_DIR}/${name}.lock" wait=0
  while ! mkdir "$path" 2>/dev/null; do
    wait=$((wait+1)); [ "$wait" -ge 60 ] && return 1
    sleep 1
  done
  trap 'rmdir "$path" 2>/dev/null || true' RETURN
  return 0
}

log() { printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" | tee -a "$LOGFILE" >&2; }

prewarm_once() {
  # WPScan DB (best effort)
  if _lock wpscan; then
    log "WPScan: updating vulnerability DB…"
    /usr/bin/wpscan --update >>"$LOGFILE" 2>&1 || log "WPScan update failed (continuing)"
  fi

  # Trivy DB
  if _lock trivy; then
    log "Trivy: downloading DB…"
    /usr/local/bin/trivy --download-db-only >>"$LOGFILE" 2>&1 || log "Trivy DB download failed (continuing)"
  fi

  # Nuclei templates
  if _lock nuclei; then
    log "Nuclei: updating templates…"
    nuclei -ut >>"$LOGFILE" 2>&1 || log "Nuclei update failed (continuing)"
  fi

  # rockyou wordlist (if present)
  if _lock wordlists && [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    log "Wordlists: ensuring rockyou.txt is available…"
    gzip -dk /usr/share/wordlists/rockyou.txt.gz >>"$LOGFILE" 2>&1 || true
  fi

  log "Prewarm completed."
}

# Kick background prewarm (don’t block server startup)
{ prewarm_once; } >>"$LOGFILE" 2>&1 &

# Start HexStrike MCP server
exec /opt/hexstrike/venv/bin/gunicorn \
  --bind 0.0.0.0:8888 \
  --workers 2 \
  --threads 8 \
  --timeout 3600 \
  --graceful-timeout 120 \
  --keep-alive 60 \
  "hexstrike_server:app"
