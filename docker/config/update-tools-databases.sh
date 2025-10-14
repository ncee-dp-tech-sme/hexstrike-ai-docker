#!/usr/bin/env bash
# HexStrike — update security databases (idempotent; stdout/stderr only)

set -euo pipefail

log() { printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >&2; }

# Print-only sanity (do not create anything)
log "WPScan DB dir:        ${HOME}/.wpscan/db        [$([ -d "$HOME/.wpscan/db" ] && echo present || echo missing)]"
log "Trivy cache dir:       ${HOME}/.cache/trivy      [$([ -d "$HOME/.cache/trivy" ] && echo present || echo missing)]"
log "Nuclei templates dir:  ${HOME}/nuclei-templates  [$([ -d "$HOME/nuclei-templates" ] && echo present || echo missing)]"
log "ExploitDB dir:         /usr/share/exploitdb      [$([ -d "/usr/share/exploitdb" ] && echo present || echo missing)]"
log "Nikto data dir:        /var/lib/nikto            [$([ -d "/var/lib/nikto" ] && echo present || echo missing)]"
log "Nmap scripts DB:       /usr/share/nmap/scripts/script.db [$([ -f "/usr/share/nmap/scripts/script.db" ] && echo present || echo missing)]"
log "ZAP home:              ${HOME}/.ZAP              [$([ -d "$HOME/.ZAP" ] && echo present || echo missing)]"

# WPScan
log "WPScan: updating vulnerability DB…"
/usr/local/bin/wpscan --update || log "WPScan update failed (continuing)"

# Trivy (download DB only; no scan)
log "Trivy: downloading vulnerability DB only…"
trivy image --download-db-only --cache-dir "$HOME/.cache/trivy" || log "Trivy DB download failed (continuing)"

# Nuclei
log "Nuclei: updating templates…"
nuclei -ut -ud "$HOME/nuclei-templates" || log "Nuclei update failed (continuing)"

# ExploitDB (searchsploit)
log "ExploitDB: updating (searchsploit -u)…"
searchsploit -u || log "ExploitDB update failed (continuing)"

# Nikto
log "Nikto: updating signatures (-update)…"
nikto -update || log "Nikto update failed (continuing)"

# Nmap script DB
log "Nmap: rebuilding script database (script.db)…"
nmap --script-updatedb || log "Nmap script-updatedb failed (continuing)"

# OWASP ZAP add-ons (will create ~/.ZAP if missing)
if command -v zap.sh >/dev/null 2>&1; then
  log "ZAP: updating add-ons (headless)…"
  zap.sh -cmd -addonupdate || log "ZAP add-on update failed (continuing)"
else
  log "ZAP: zap.sh not found; skipping"
fi

log "Security databases update completed."
