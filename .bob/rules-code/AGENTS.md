# Code Mode Rules (Non-Obvious Only)

## Architecture Constraints

**Two-Script System (Cannot Merge):**
- `hexstrike_server.py` = Flask API server (8888)
- `hexstrike_mcp.py` = MCP client proxy
- These MUST remain separate - server runs independently, client connects via HTTP
- No access to MCP or Browser tools in this mode

**Color System Synchronization:**
- `ModernVisualEngine.COLORS` (server) and `HexStrikeColors` (client) MUST match exactly
- Any color constant change requires updating BOTH files
- Uses ANSI 256-color codes (e.g., `\033[38;5;160m`), NOT basic 16-color codes
- Primary theme: CRIMSON (160), HACKER_RED (196), BLOOD_RED (124)

## Python Environment Patterns

**Multiple Python Versions in Docker:**
- System Python: 3.10 (Kali default)
- Venv Python: 3.10 at `/opt/hexstrike/venv` (all pip installs)
- Python 3.12: `/usr/local/bin/python3.12` (Prowler/Pacu via pipx ONLY)
- CloudMapper venv: 3.10 at `/opt/venvs/cloudmapper` (currently disabled in Dockerfile)

**Import Resolution:**
- Server automatically uses venv via `ENV PATH` in Dockerfile
- Direct Python calls MUST use: `/opt/hexstrike/venv/bin/python3`
- pipx installs go to `/root/.local/bin` (added to PATH)

## Tool Wrapper System (Critical)

**Wrappers Exist Because:**
- `hashcat-utils` package has no single binary → wrapper delegates to `cap2hccapx`
- `volatility3`, `volatility`, `vol.py`, `vol` → all symlink to same Python module
- `insomnia` → wrapper sets Node 18 PATH (isolated from system Node)
- `cloudmapper` → wrapper activates dedicated Python 3.10 venv (currently disabled)
- `patator` → wrapper uses `runpy` to execute `/usr/share/patator/patator.py`

**Symlink Aliases (lines 786-812 in Dockerfile):**
- `exploit-db` → `searchsploit`
- `postman` → `newman`
- `httpie` → `http`
- `graphql-scanner` → `graphql-inspector`
- `sleuthkit` → `tsk_loaddb`
- `metasploit` → `msfconsole`
- `have-i-been-pwned` → `pwned`
- `clair` → `clairctl`
- `bulk-extractor` → `bulk_extractor`
- `one-gadget` → `one_gadget`

## Logging Patterns

**Fallback Strategy (lines 74-92 in hexstrike_server.py):**
```python
try:
    # Attempt file + stdout logging
    logging.basicConfig(handlers=[StreamHandler, FileHandler('hexstrike.log')])
except PermissionError:
    # Fallback to stdout only
    logging.basicConfig(handlers=[StreamHandler])
```
- NEVER assume log file exists
- Server continues running even if file write fails

## Configuration Overrides

**Environment Variables:**
- `HEXSTRIKE_PORT` → server port (default: 8888)
- `HEXSTRIKE_HOST` → bind address (default: 127.0.0.1)
- `COMMAND_TIMEOUT` → tool execution timeout (default: 3600s)
- `CLAIR_ADDR` → Clair API endpoint (default: http://127.0.0.1:10080)
- `MSF_DB_URL` → Metasploit database (empty = disabled)

**Docker Compose Overrides:**
- Port mapping: `8888:8888` (bridge mode, NOT host mode)
- Privileged: `true` (required for 127+ tools with raw sockets/ptrace)
- Security opts: `seccomp=unconfined`, `apparmor=unconfined`, `label=disable`

## MCP Client Stdio Detection (Non-Obvious)

**Health Check Skipping (lines 165-193 in hexstrike_mcp.py):**
```python
if sys.stdin.isatty() or sys.stdout.isatty():
    # Run HTTP health checks with retries
else:
    # Skip checks - running under MCP host
```
- When stdin/stdout not TTY → assumes MCP host environment
- Prevents 3x retry delays during Claude Desktop/Cursor startup
- Manual testing REQUIRES TTY terminal to see connection attempts

## Docker Build Stages (Multi-Stage Pattern)

**Stage A (python312-base):**
- Python 3.12 runtime for Prowler/Pacu (they require 3.12, NOT 3.10)

**Stage B (cloudmapper-builder):**
- Python 3.10 + pyjq compilation
- Currently disabled (lines 16-49 in Dockerfile commented out)
- If re-enabled: MUST use dedicated venv at `/opt/venvs/cloudmapper`

**Stage C (insomnia-node18-builder):**
- Isolated Node.js 18 runtime for insomnia-inso CLI
- NOT system Node - prevents version conflicts
- Artifacts copied to `/opt/insomnia-node18` in final stage

**Stage D (Final):**
- Kali Linux base with all tools
- Copies Python 3.12 from Stage A
- Copies Node 18 artifacts from Stage C
- CloudMapper from Stage B (currently disabled)

## Volume Mount Patterns

**Data Persistence:**
- `../data/trivy` → `/root/.cache/trivy`
- `../data/wpscan` → `/root/.wpscan/db`
- `../data/nuclei-templates` → `/root/nuclei-templates`
- `../data/workspace` → `/workspace` (default for checkov scans)
- `../logs/hexstrike.log` → `/opt/hexstrike/hexstrike.log`

**Socket Mounts (kube-bench requirement):**
- `/var/run/docker.sock` → Docker API socket
- `/run/podman/podman.sock` → Podman API socket (if using Podman)