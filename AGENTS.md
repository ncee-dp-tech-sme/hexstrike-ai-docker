# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Architecture (Non-Obvious)

**Two-Process System (Critical):**
- `hexstrike_server.py` runs Flask API server on port 8888 (NOT a standalone tool)
- `hexstrike_mcp.py` is MCP client that MUST connect to running server via `--server http://localhost:8888`
- Server MUST be running before MCP client starts, or tools will fail silently

**Docker Multi-Stage Build Pattern:**
- Stage A: Python 3.12 base (Prowler/Pacu require 3.12, NOT 3.10)
- Stage B: CloudMapper builder (Python 3.10 + pyjq - currently disabled in Dockerfile)
- Stage C: Node.js 18 isolated runtime (insomnia-inso ONLY, not system Node)
- Stage D: Final Kali Linux with all tools

## Critical Commands

**Server Startup (Required First):**
```bash
# Native Python (requires venv activation first)
python3 hexstrike_server.py

# Docker (preferred - includes all 150+ tools)
./docker/start-docker-mcp-server.sh
```

**MCP Client (After Server Running):**
```bash
# MUST specify --server flag pointing to running server
python3 hexstrike_mcp.py --server http://localhost:8888 --timeout 1800
```

**Docker Build (30-60 min):**
```bash
./docker/build-docker-image.sh
```

## Non-Obvious Patterns

**Port Configuration:**
- Default: 8888 (override via `HEXSTRIKE_PORT` env var)
- Server binds to `127.0.0.1` by default (override via `HEXSTRIKE_HOST`)
- Docker exposes 8888:8888 in bridge mode (NOT host mode despite comments)

**Logging Fallback:**
- Server attempts `hexstrike.log` file creation
- Falls back to stdout-only if PermissionError (lines 84-92 in hexstrike_server.py)

**Tool Wrappers (Critical for Health Checks):**
- `hashcat-utils` wrapper delegates to `cap2hccapx` (no actual `hashcat-utils` binary exists)
- `volatility3`, `volatility`, `vol.py`, `vol` all point to same Python module
- CloudMapper uses dedicated venv at `/opt/venvs/cloudmapper` (currently disabled)
- Insomnia CLI uses isolated Node 18 at `/opt/insomnia-node18` (NOT system Node)

**Virtual Environment:**
- Docker creates venv at `/opt/hexstrike/venv` (NOT system Python)
- All pip installs go into this venv, activated via `ENV PATH`

**Color System:**
- `ModernVisualEngine.COLORS` and `HexStrikeColors` MUST match exactly
- Uses "blood-red" theme with ANSI 256-color codes (not basic 16 colors)
- Primary border: CRIMSON (160), Accent: HACKER_RED (196)

**MCP Client Stdio Detection:**
- Skips HTTP health checks if stdin/stdout not TTY (lines 165-193 in hexstrike_mcp.py)
- Prevents bootstrap delays when running under MCP host

**Docker Privileged Mode:**
- Required for 127+ security tools (raw sockets, network admin, ptrace)
- Alternative: Fine-grained capabilities (lines 92-108 in docker-compose.yml) - untested

**Volume Mounts (Data Persistence):**
- Tool databases persist in `../data/*` directories
- Logs in `../logs/hexstrike.log`
- Workspace in `../data/workspace` (default for checkov scans)

## Testing

No automated test suite exists. Manual testing via:
```bash
# Health check
curl http://localhost:8888/health

# Tool availability check (returns JSON with 150+ tools)
curl http://localhost:8888/api/tools/status