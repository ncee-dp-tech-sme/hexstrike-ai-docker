# Ask Mode Rules (Non-Obvious Only)

## Architecture Context

**Two-Process System:**
- `hexstrike_server.py` = Flask API server (port 8888)
- `hexstrike_mcp.py` = MCP client proxy connecting to server
- Server must be running for any MCP operations to work
- This is a security testing framework, NOT a general-purpose tool

**Project Structure (Counterintuitive):**
- `hexstrike_server.py` contains ALL business logic (150+ tool integrations)
- `hexstrike_mcp.py` is thin wrapper exposing server via MCP protocol
- Docker multi-stage build creates single image with 150+ security tools
- No separate "client" and "server" images - single unified container

## Documentation Patterns

**Tool Wrappers (Hidden Implementation):**
- Many "tools" listed in README are actually symlinks/wrappers (Dockerfile lines 746-812)
- `hashcat-utils` doesn't exist as binary - wrapper calls `cap2hccapx`
- `volatility3`, `volatility`, `vol.py`, `vol` all point to same Python module
- `exploit-db` → `searchsploit`, `postman` → `newman`, `httpie` → `http`
- This is intentional for health check compatibility

**Python Version Confusion:**
- System Python: 3.10 (Kali default)
- Venv Python: 3.10 at `/opt/hexstrike/venv` (most tools)
- Python 3.12: `/usr/local/bin/python3.12` (Prowler/Pacu ONLY)
- CloudMapper: Python 3.10 at `/opt/venvs/cloudmapper` (currently disabled)
- NOT a bug - different tools require different Python versions

**Docker Networking (Misleading Comments):**
- docker-compose.yml says "host networking" but uses `network_mode: bridge`
- Port mapping is `8888:8888` (bridge mode, NOT host mode)
- Comments in file are outdated - actual config is bridge mode
- This is intentional for better isolation

## Color System (Important for Output Interpretation)

**ANSI 256-Color Codes (NOT Basic 16):**
- Uses codes like `\033[38;5;160m` (256-color palette)
- NOT basic codes like `\033[91m` (16-color palette)
- Primary theme: CRIMSON (160), HACKER_RED (196), BLOOD_RED (124)
- `ModernVisualEngine.COLORS` and `HexStrikeColors` must stay synchronized

**Status Color Meanings:**
- VULN_CRITICAL: Dark red background (124) + white bold
- VULN_HIGH: Bright red bold (196)
- TOOL_RUNNING: Blinking green (46)
- TOOL_FAILED: Bold red (196)
- TOOL_RECOVERY: Bold purple (129)

## Volume Mounts (Data Persistence)

**Tool Database Locations:**
- Trivy: `../data/trivy` → `/root/.cache/trivy`
- WPScan: `../data/wpscan` → `/root/.wpscan/db`
- Nuclei: `../data/nuclei-templates` → `/root/nuclei-templates`
- Metasploit: `../data/msf` → `/root/.msf4`
- ExploitDB: `../data/exploitdb` → `/usr/share/exploitdb`

**Why These Paths:**
- Tools expect specific locations (e.g., Trivy always uses `~/.cache/trivy`)
- Volume mounts preserve data across container restarts
- First-time warmup happens in background (non-blocking)

## MCP Client Behavior (Non-Obvious)

**Stdio Detection (lines 165-193 in hexstrike_mcp.py):**
- If stdin/stdout not TTY → skips HTTP health checks
- Prevents 3x retry delays when running under MCP host
- Manual testing REQUIRES TTY terminal to see connection attempts
- This is why "connection failed" messages don't appear in Claude Desktop

**Health Check Strategy:**
- MCP client tries 3 times with 2-second delays
- Only happens if running in interactive terminal
- Continues anyway if checks fail (doesn't block startup)
- Server health endpoint: `http://localhost:8888/health`

## Build Time Expectations

**Docker Build Duration:**
- 30-60 minutes typical (depends on network speed)
- Multi-stage build with 4 stages (Python 3.12, CloudMapper, Node 18, Final)
- Downloads 150+ tools from official sources
- CloudMapper stage currently disabled (lines 16-49 commented out)

**Why So Long:**
- Kali Linux base image is large (~2GB)
- Compiles some tools from source (pyjq, etc.)
- Downloads tool databases (nuclei templates, exploitdb, etc.)
- Installs 150+ security tools with dependencies

## Testing Strategy

**No Automated Tests:**
- Manual health check: `curl http://localhost:8888/health`
- Tool availability: `curl http://localhost:8888/api/tools/status`
- Process dashboard: `curl http://localhost:8888/api/processes/dashboard`
- This is intentional - security tools are hard to unit test

## Common Misconceptions

**"Why privileged mode?"**
- Required for 127+ security tools (raw sockets, ptrace, network admin)
- nmap -sS, masscan, tcpdump, wireshark need raw socket capability
- metasploit, gdb, volatility need ptrace capability
- Alternative: Fine-grained capabilities (untested, may break tools)

**"Why bridge mode not host?"**
- Better isolation despite performance cost
- Easier port management (8888:8888 mapping)
- Comments in docker-compose.yml are misleading/outdated
- Actual config uses bridge mode

**"Why multiple Python versions?"**
- Prowler/Pacu require Python 3.12 (won't work on 3.10)
- Most tools work on Python 3.10 (Kali default)
- CloudMapper needs Python 3.10 + specific pyjq version
- NOT a mistake - different tools have incompatible requirements