# HexStrike AI MCP Server - Docker Build & Deployment Guide

This guide covers building and running the HexStrike AI MCP Server using Docker.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start with Docker Compose](#quick-start-with-docker-compose)
3. [Manual Docker Build](#manual-docker-build)
4. [Runtime Configuration](#runtime-configuration)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later (optional, for compose deployment)

### Verify Docker Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose --version

# Verify Docker is running
docker ps
```

---

## Quick Start with Docker Compose

**Recommended method** for easy deployment and management.

### 1. Navigate to Repository

```bash
cd /path/to/hexstrike-ai
```

### 2. Start with Docker Compose

```bash
# Build and start container in detached mode
docker-compose -f docker/docker-compose.yml up -d

# View logs
docker-compose -f docker/docker-compose.yml logs -f

# Check status
docker-compose -f docker/docker-compose.yml ps
```

### 3. Verify Installation

```bash
# Test health endpoint
curl http://localhost:8888/health

# Expected response:
# {"status": "healthy", "timestamp": "..."}
```

### 4. Stop and Remove

```bash
# Stop container
docker-compose -f docker/docker-compose.yml down

# Stop and remove volumes
docker-compose -f docker/docker-compose.yml down -v
```
---

## Manual Docker Build

For custom builds or when not using Docker Compose.

### 1. Build the Image

```bash
# From repository root, launch the script. Logs are stored in build.log file
./docker/build-docker-image.sh
```

### 2. Run the Container

```bash
./docker/run-docker-mcp-server.sh
```

## Runtime Configuration

### Required Capabilities

HexStrike requires specific Linux capabilities for security tool operations:

| Capability | Purpose | Required For |
|------------|---------|--------------|
| `NET_RAW` | Raw socket access | nmap, masscan, rustscan, arp-scan |
| `NET_ADMIN` | Network configuration | Various network tools |

**Note**: Running with `--privileged` is NOT recommended for security reasons.
Run the container as `root` (default) or ensure your runtime allows adding these capabilities, otherwise tools such as nmap and masscan will fail to open raw sockets.

### Port Configuration

Default port: **8888**

To use a different port:

```bash
# Docker run
docker run --rm -it \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -p 9000:8888 \
  hexstrike-ai:v6.0

# Docker Compose
# Edit docker-compose.yml:
# ports:
#   - "9000:8888"
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PYTHONUNBUFFERED` | `1` | Disable Python output buffering |
| `DEBUG_MODE` | `false` | Enable debug logging |
| `MCP_PORT` | `8888` | MCP server port |

Example:
```bash
docker run --rm -it \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -p 8888:8888 \
  -e DEBUG_MODE=true \
  hexstrike-ai:v6.0
```

### Volume Mounts

**Recommended volumes:**

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `./scan-results` | `/opt/hexstrike/results` | Store scan outputs |
| `./logs` | `/opt/hexstrike/logs` | Application logs |
| `./wordlists` | `/opt/hexstrike/wordlists` | Custom wordlists |

---

## Troubleshooting

### Runtime Issues

**Problem**: Container immediately exits
```bash
# Check logs for error messages
docker logs hexstrike-mcp

# Run in interactive mode for debugging
docker run --rm -it \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -p 8888:8888 \
  hexstrike-ai:v6.0 \
  /bin/bash
```

**Problem**: Health check failing
```bash
# Check if server is actually listening
docker exec hexstrike-mcp netstat -tlnp | grep 8888

# Test health endpoint from inside container
docker exec hexstrike-mcp curl http://localhost:8888/health
```

**Problem**: Tools require root privileges
```bash
# Verify capabilities are set
docker inspect hexstrike-mcp | grep -A 10 CapAdd

# If needed, run with --privileged (NOT recommended for production)
docker run --rm -it --privileged -p 8888:8888 hexstrike-ai:v6.0
```

**Problem**: Cannot connect to MCP server from host
```bash
# Check port binding
docker port hexstrike-mcp

# Verify firewall rules
sudo iptables -L -n | grep 8888

# Test from host
curl http://localhost:8888/health
```
---

## Security Considerations

### Network Isolation

For production deployments, consider:

```yaml
# docker-compose.yml
networks:
  hexstrike-isolated:
    driver: bridge
    internal: true
```

### Read-Only Filesystem

For enhanced security (may break some tools):

```bash
docker run --rm -it \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  --read-only \
  --tmpfs /tmp \
  -p 8888:8888 \
  hexstrike-ai:v6.0
```