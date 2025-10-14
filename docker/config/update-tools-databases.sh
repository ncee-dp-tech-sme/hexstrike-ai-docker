#!/usr/bin/env bash
# HexStrike - update security databases (idempotent, stdout/stderr only)

set -euo pipefail

# Expected mounted paths (do NOT create here)
# - WPScan DB:        $HOME/.wpscan/db
# - Trivy cache:      $HOME/.cache/trivy
# - Nuclei templates: $HOME/nuclei-templates

log() { printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >&2; }

# Sanity (print-only): show what exists; do not create anything
log "WPScan DB dir:        ${HOME}/.wpscan/db  [$( [ -d "$HOME/.wpscan/db" ] && echo present || echo missing )]"
log "Trivy cache dir:       ${HOME}/.cache/trivy  [$( [ -d "$HOME/.cache/trivy" ] && echo present || echo missing )]"
log "Nuclei templates dir:  ${HOME}/nuclei-templates  [$( [ -d "$HOME/nuclei-templates" ] && echo present || echo missing )]"

# WPScan DB
log "WPScan: updating vulnerability DB…"
/usr/local/bin/wpscan --update || log "WPScan update failed (continuing)"

# Trivy DB (download DB only; no scan)
log "Trivy: downloading vulnerability DB only…"
trivy image --download-db-only --cache-dir "$HOME/.cache/trivy" || log "Trivy DB download failed (continuing)"

# Nuclei templates
log "Nuclei: updating templates…"
nuclei -ut -ud "$HOME/nuclei-templates" || log "Nuclei update failed (continuing)"

# rockyou wordlist (best-effort)
if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
  log "Wordlists: ensuring rockyou.txt is available…"
  gzip -dk /usr/share/wordlists/rockyou.txt.gz || true
fi

log "Security databases update completed."
