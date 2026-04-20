#!/bin/bash
# configure_mcp.sh - Configure MCP client for HexStrike Streaming Server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HEXSTRIKE_SERVER="${HEXSTRIKE_SERVER:-http://localhost:8888}"
HEXSTRIKE_TIMEOUT="${HEXSTRIKE_TIMEOUT:-1800}"
MCP_CLIENT_PATH="${MCP_CLIENT_PATH:-$(pwd)/../../hexstrike_mcp.py}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  HexStrike Streaming Server - MCP Configuration Helper        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if server is running
echo -e "${YELLOW}[1/5]${NC} Checking if HexStrike streaming server is running..."
if curl -s -f "${HEXSTRIKE_SERVER}/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Server is running at ${HEXSTRIKE_SERVER}"
else
    echo -e "${RED}✗${NC} Server is not responding at ${HEXSTRIKE_SERVER}"
    echo -e "${YELLOW}→${NC} Please start the server first:"
    echo -e "   ${BLUE}docker-compose up -d${NC}"
    echo -e "   or"
    echo -e "   ${BLUE}python3 hexstrike_server.py${NC}"
    exit 1
fi

# Check if MCP client exists
echo -e "${YELLOW}[2/5]${NC} Checking for MCP client..."
if [ -f "$MCP_CLIENT_PATH" ]; then
    echo -e "${GREEN}✓${NC} MCP client found at ${MCP_CLIENT_PATH}"
else
    echo -e "${RED}✗${NC} MCP client not found at ${MCP_CLIENT_PATH}"
    echo -e "${YELLOW}→${NC} Please set MCP_CLIENT_PATH environment variable"
    exit 1
fi

# Detect OS and set config paths
echo -e "${YELLOW}[3/5]${NC} Detecting operating system..."
OS="$(uname -s)"
case "${OS}" in
    Darwin*)
        CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
        CURSOR_CONFIG="$HOME/.cursor/mcp_config.json"
        echo -e "${GREEN}✓${NC} Detected macOS"
        ;;
    Linux*)
        CLAUDE_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
        CURSOR_CONFIG="$HOME/.cursor/mcp_config.json"
        echo -e "${GREEN}✓${NC} Detected Linux"
        ;;
    *)
        echo -e "${RED}✗${NC} Unsupported OS: ${OS}"
        exit 1
        ;;
esac

# Generate MCP configuration
echo -e "${YELLOW}[4/5]${NC} Generating MCP configuration..."

MCP_CONFIG=$(cat <<EOF
{
  "mcpServers": {
    "hexstrike-streaming": {
      "command": "python3",
      "args": [
        "${MCP_CLIENT_PATH}",
        "--server",
        "${HEXSTRIKE_SERVER}",
        "--timeout",
        "${HEXSTRIKE_TIMEOUT}"
      ],
      "env": {
        "HEXSTRIKE_SERVER": "${HEXSTRIKE_SERVER}",
        "HEXSTRIKE_STREAMING": "true"
      }
    }
  }
}
EOF
)

echo -e "${GREEN}✓${NC} Configuration generated"

# Offer to install configuration
echo -e "${YELLOW}[5/5]${NC} Installation options:"
echo ""
echo "Choose where to install MCP configuration:"
echo "  1) Claude Desktop"
echo "  2) Cursor IDE"
echo "  3) Both"
echo "  4) Show config only (don't install)"
echo "  5) Exit"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo -e "${BLUE}→${NC} Installing for Claude Desktop..."
        mkdir -p "$(dirname "$CLAUDE_CONFIG")"
        echo "$MCP_CONFIG" > "$CLAUDE_CONFIG"
        echo -e "${GREEN}✓${NC} Configuration saved to: ${CLAUDE_CONFIG}"
        echo -e "${YELLOW}→${NC} Restart Claude Desktop to apply changes"
        ;;
    2)
        echo -e "${BLUE}→${NC} Installing for Cursor IDE..."
        mkdir -p "$(dirname "$CURSOR_CONFIG")"
        echo "$MCP_CONFIG" > "$CURSOR_CONFIG"
        echo -e "${GREEN}✓${NC} Configuration saved to: ${CURSOR_CONFIG}"
        echo -e "${YELLOW}→${NC} Restart Cursor IDE to apply changes"
        ;;
    3)
        echo -e "${BLUE}→${NC} Installing for both Claude Desktop and Cursor IDE..."
        mkdir -p "$(dirname "$CLAUDE_CONFIG")"
        mkdir -p "$(dirname "$CURSOR_CONFIG")"
        echo "$MCP_CONFIG" > "$CLAUDE_CONFIG"
        echo "$MCP_CONFIG" > "$CURSOR_CONFIG"
        echo -e "${GREEN}✓${NC} Configuration saved to:"
        echo -e "   - ${CLAUDE_CONFIG}"
        echo -e "   - ${CURSOR_CONFIG}"
        echo -e "${YELLOW}→${NC} Restart both applications to apply changes"
        ;;
    4)
        echo -e "${BLUE}→${NC} MCP Configuration:"
        echo ""
        echo "$MCP_CONFIG"
        echo ""
        echo -e "${YELLOW}→${NC} Save this to:"
        echo -e "   Claude Desktop: ${CLAUDE_CONFIG}"
        echo -e "   Cursor IDE: ${CURSOR_CONFIG}"
        ;;
    5)
        echo -e "${YELLOW}→${NC} Exiting without changes"
        exit 0
        ;;
    *)
        echo -e "${RED}✗${NC} Invalid choice"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Configuration Complete!                                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Restart your IDE/Claude Desktop"
echo -e "  2. Test the connection with: ${BLUE}curl ${HEXSTRIKE_SERVER}/health${NC}"
echo -e "  3. Run streaming tests: ${BLUE}python3 test_streaming.py${NC}"
echo ""
echo -e "${BLUE}Streaming endpoints available at:${NC}"
echo -e "  - ${HEXSTRIKE_SERVER}/api/stream/create"
echo -e "  - ${HEXSTRIKE_SERVER}/api/stream/<task_id>"
echo -e "  - ${HEXSTRIKE_SERVER}/api/tools/<tool>/stream"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "  - README.md - Quick start guide"
echo -e "  - STREAMING_API_GUIDE.md - Complete API reference"
echo ""

# Made with Bob
