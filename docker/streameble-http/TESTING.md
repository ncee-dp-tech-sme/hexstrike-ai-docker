# Testing the HexStrike Streaming API

## Prerequisites

The test script requires Python dependencies from the project's virtual environment.

## Authentication

The test script supports HTTP Basic Authentication via environment variables:

```bash
export HEXSTRIKE_USERNAME="your-username"
export HEXSTRIKE_PASSWORD="your-password"
export HEXSTRIKE_SERVER_URL="https://your-server-url.com"  # Optional, defaults to configured URL
```

## Running the Tests

### Option 1: Activate Virtual Environment (Recommended)
```bash
# From project root
source .venv/bin/activate

# Without authentication
python3 docker/streameble-http/test_streaming.py

# With authentication
export HEXSTRIKE_USERNAME="admin"
export HEXSTRIKE_PASSWORD="your-password"
python3 docker/streameble-http/test_streaming.py
```

### Option 2: Use Virtual Environment Python Directly
```bash
# From project root
.venv/bin/python3 docker/streameble-http/test_streaming.py
```

### Option 3: One-liner with Authentication
```bash
# From project root
HEXSTRIKE_USERNAME="admin" HEXSTRIKE_PASSWORD="your-password" .venv/bin/python3 docker/streameble-http/test_streaming.py
```

### Option 4: Run from Docker Container
```bash
# If testing against the containerized server
docker exec -it hexstrike-ai python3 /opt/hexstrike/test_streaming.py
```

## Common Issues

### ModuleNotFoundError: No module named 'requests'

**Cause:** Running the script with system Python instead of the virtual environment Python.

**Solution:** Use one of the methods above to ensure the virtual environment is active or use the venv Python directly.

### 401 Unauthorized Error

**Cause:** The server requires authentication but credentials were not provided.

**Solution:** Set the `HEXSTRIKE_USERNAME` and `HEXSTRIKE_PASSWORD` environment variables:
```bash
export HEXSTRIKE_USERNAME="your-username"
export HEXSTRIKE_PASSWORD="your-password"
```

## Test Configuration

### Environment Variables

- `HEXSTRIKE_SERVER_URL`: Server URL (default: configured in script)
- `HEXSTRIKE_USERNAME`: Username for HTTP Basic Auth (optional)
- `HEXSTRIKE_PASSWORD`: Password for HTTP Basic Auth (optional)

### Example: Testing Against Different Servers

```bash
# Local server (no auth)
HEXSTRIKE_SERVER_URL="http://localhost:8888" .venv/bin/python3 docker/streameble-http/test_streaming.py

# Remote server with auth
HEXSTRIKE_SERVER_URL="https://hexstrike.example.com" \
HEXSTRIKE_USERNAME="admin" \
HEXSTRIKE_PASSWORD="secret" \
.venv/bin/python3 docker/streameble-http/test_streaming.py
```