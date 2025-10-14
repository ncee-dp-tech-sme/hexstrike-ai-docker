#!/usr/bin/env bash
# HexStrike - on-demand cache updater (safe to run anytime)
# - Updates: WPScan DB, Trivy DB, Nuclei templates, rockyou wordlist (if present)
# - Best effort: failures won't crash the script
# - Uses tiny per-tool locks to avoid concurrent writes

set -euo pipefail

MAINT_DIR="/opt/hexstrike/maintenance"
LOCK_DIR="${MAINT_DIR}/locks"
LOGFILE="${MAINT_DIR}/updates.log"

mkdir -p "$LOCK_DIR" "$MAINT_DIR" \
         "${HOME}/.cache/wpscan/db" \
         "${HOME}/.cache/trivy" \
         "${HOME}/.config/amass" \
         "${HOME}/nuclei-templates" || true
touch "$LOGFILE" || true

lock() {
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

if lock wpscan; then
  log "WPScan: updating vulnerability DB…"
  /usr/bin/wpscan --update >>"$LOGFILE" 2>&1 || log "WPScan update failed (continuing)"
fi

if lock trivy; then
  log "Trivy: downloading DB…"
  /usr/local/bin/trivy --download-db-only >>"$LOGFILE" 2>&1 || log "Trivy DB download failed (continuing)"
fi

if lock nuclei; then
  log "Nuclei: updating templates…"
  nuclei -ut >>"$LOGFILE" 2>&1 || log "Nuclei update failed (continuing)"
fi

if lock wordlists && [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
  log "Wordlists: ensuring rockyou.txt is available…"
  gzip -dk /usr/share/wordlists/rockyou.txt.gz >>"$LOGFILE" 2>&1 || true
fi

log "Cache update completed."
