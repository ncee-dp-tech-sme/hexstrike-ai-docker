# Plan Mode Rules (Non-Obvious Only)

## Architecture Constraints

**Two-Process Dependency (Critical for Planning):**
- `hexstrike_server.py` = Flask API server (all business logic)
- `hexstrike_mcp.py` = MCP client proxy (thin wrapper)
- Server MUST be running before any MCP operations
- Plans involving MCP tools require server availability check first

**Multi-Stage Docker Build (30-60 min):**
- Stage A: Python 3.12 base (Prowler/Pacu only)
- Stage B: CloudMapper builder (currently disabled)
- Stage C: Node.js 18 isolated (insomnia-inso only)
- Stage D: Final Kali Linux with 150+ tools
- Plan for long build times in deployment strategies

## Hidden Coupling Between Components

**Tool Wrapper Dependencies:**
- Many "tools" are symlinks/wrappers (Dockerfile lines 746-812)
- Changing one tool may break health checks for "different" tool
- Example: `hashcat-utils` wrapper calls `cap2hccapx` - both must exist
- Example: `volatility3`, `volatility`, `vol.py`, `vol` all point to same module
- Plans to "update one tool" may require updating multiple wrappers

**Color System Coupling:**
- `ModernVisualEngine.COLORS` (server) and `HexStrikeColors` (client) MUST match
- Changing colors in one file breaks visual consistency in other
- Uses ANSI 256-color codes (not basic 16-color)
- Plans for UI changes require updating BOTH files

**Python Version Dependencies:**
- System: Python 3.10 (Kali default, most tools)
- Venv: Python 3.10 at `/opt/hexstrike/venv` (pip installs)
- Python 3.12: `/usr/local/bin/python3.12` (Prowler/Pacu ONLY)
- CloudMapper: Python 3.10 at `/opt/venvs/cloudmapper` (disabled)
- Plans to "upgrade Python" will break Prowler/Pacu or other tools

## Non-Standard Patterns That Must Be Followed

**Logging Fallback Pattern (lines 74-92 in hexstrike_server.py):**
```python
try:
    logging.basicConfig(handlers=[StreamHandler, FileHandler('hexstrike.log')])
except PermissionError:
    logging.basicConfig(handlers=[StreamHandler])
```
- Server continues even if log file creation fails
- Plans must account for stdout-only logging in restricted environments
- NOT a bug - intentional graceful degradation

**MCP Client Stdio Detection (lines 165-193 in hexstrike_mcp.py):**
```python
if sys.stdin.isatty() or sys.stdout.isatty():
    # Run HTTP health checks with retries
else:
    # Skip checks - running under MCP host
```
- Skips health checks when not in TTY (MCP host environment)
- Plans for "better error messages" must preserve this behavior
- Prevents 3x retry delays during Claude Desktop/Cursor startup

**Docker Privileged Mode Requirement:**
- 127+ security tools require privileged mode (raw sockets, ptrace, network admin)
- Fine-grained capabilities (docker-compose.yml lines 92-108) are untested
- Plans to "harden security" by removing privileged mode will break tools
- Alternative approaches need extensive testing

## Performance Bottlenecks Discovered Through Investigation

**Docker Build Time:**
- 30-60 minutes typical (network-dependent)
- Multi-stage build with 4 stages
- Downloads 150+ tools from official sources
- Plans for "faster builds" should focus on layer caching, not reducing tools

**First Container Start:**
- Background database warmup (non-blocking)
- Updates: WPScan, Trivy, Nuclei, ExploitDB, Nikto, Nmap NSE, ZAP
- Plans for "faster startup" should preserve background warmup pattern

**Volume Mount Strategy:**
- Tool databases persist in `../data/*` directories
- First-time population can be slow (GB of data)
- Plans for "clean installs" must account for re-download time

## Architectural Decisions (Non-Obvious Rationale)

**Why Bridge Mode Not Host:**
- docker-compose.yml comments say "host networking" but uses `network_mode: bridge`
- Better isolation despite performance cost
- Easier port management (8888:8888 mapping)
- Plans to "fix comments" should update comments, not change to host mode

**Why Multiple Python Versions:**
- Prowler/Pacu require Python 3.12 (incompatible with 3.10)
- Most tools require Python 3.10 (Kali default)
- CloudMapper needs Python 3.10 + specific pyjq version
- Plans to "standardize Python version" will break tools

**Why Isolated Node.js 18:**
- insomnia-inso requires Node 18 (incompatible with system Node)
- Prevents version conflicts with other Node tools
- Artifacts at `/opt/insomnia-node18` (NOT system Node)
- Plans to "use system Node" will break insomnia CLI

**Why CloudMapper Disabled:**
- Lines 16-49 in Dockerfile commented out
- Requires Python 3.10 + pyjq compilation (slow build)
- Dedicated venv at `/opt/venvs/cloudmapper`
- Plans to "re-enable" must uncomment build stage AND wrapper

## Testing Constraints

**No Automated Test Suite:**
- Manual health checks only
- Security tools are hard to unit test (require real targets)
- Plans for "adding tests" should focus on integration tests, not unit tests
- Health check endpoints: `/health`, `/api/tools/status`, `/api/processes/dashboard`

**Common Failure Modes:**
1. Server not running → MCP tools fail silently
2. Port 8888 blocked → connection refused
3. Missing privileged mode → raw socket tools fail
4. Volume permissions → database updates fail
- Plans must account for these failure modes in error handling

## Deployment Considerations

**Data Persistence Strategy:**
- Tool databases: `../data/{trivy,wpscan,nuclei-templates,amass,msf,exploitdb,zap}`
- Logs: `../logs/hexstrike.log` (fallback to stdout if write fails)
- Workspace: `../data/workspace` (default for checkov IaC scans)
- PostgreSQL: `../data/postgres` (Clair + optional Metasploit DB)
- Plans for "stateless deployment" must preserve these mounts

**Port Configuration:**
- Default: 8888 (override via `HEXSTRIKE_PORT` env var)
- Server binds to `127.0.0.1` by default (override via `HEXSTRIKE_HOST`)
- Docker exposes 8888:8888 in bridge mode
- Plans for "multi-instance deployment" need unique ports per instance