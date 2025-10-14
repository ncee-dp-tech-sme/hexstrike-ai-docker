#!/usr/bin/env bash
# HexStrike - unified on-demand security databases updater (safe to run anytime)
# - Updates: WPScan DB, Trivy DB, Nuclei templates, rockyou wordlist (if present)
# - Best effort: failures won't crash the script
# - All logs go to stdout/stderr (no files)

set -euo pipefail

# Persistent paths (mounted via docker-compose)
CACHE_WPSCAN_DB="${HOME}/.cache/wpscan/db"
CACHE_TRIVY="${HOME}/.cache/trivy"
CONF_AMASS="${HOME}/.config/amass"
NUCLEI_TEMPLATES="${HOME}/nuclei-templates"

# Ensure directories exist
mkdir -p "$CACHE_WPSCAN_DB" "$CACHE_TRIVY" "$CONF_AMASS" "$NUCLEI_TEMPLATES" || true

log() { printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >&2; }

# WPScan DB (best effort)
log "WPScan: updating vulnerability DB…"
/usr/local/bin/wpscan --update || log "WPScan update failed (continuing)"

# Trivy DB (download DB only; no scan, fast and deterministic)
log "Trivy: downloading vulnerability DB only…"
trivy image --download-db-only --cache-dir "$CACHE_TRIVY" || log "Trivy DB download failed (continuing)"

# Nuclei templates
log "Nuclei: updating templates…"
nuclei -ut -ud "$NUCLEI_TEMPLATES" || log "Nuclei update failed (continuing)"

# rockyou wordlist (if present)
if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
  log "Wordlists: ensuring rockyou.txt is available…"
  gzip -dk /usr/share/wordlists/rockyou.txt.gz || true
fi

log "Security databases update completed."
