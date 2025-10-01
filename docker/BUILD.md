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
- **System Requirements**:
  - CPU: 2+ cores (4+ recommended)
  - RAM: 4GB minimum (8GB recommended)
  - Disk: 5GB free space for image + scan results

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

## Included Tooling Snapshot

The container image pre-installs the tooling referenced in the README so you can start scanning immediately:

- **Network Recon:** `nmap`, `masscan`, `autorecon`, `amass`, `subfinder`, `theharvester`, `responder`, `netexec`, `enum4linux-ng`, `arp-scan`, `rustscan`
- **Web Security:** `gobuster`, `feroxbuster`, `ffuf`, `dirb`, `dirsearch`, `nikto`, `sqlmap`, `wpscan`, `arjun`, `paramspider`, `hakrawler`, `wafw00f`, plus Go binaries such as `nuclei`, `httpx`, `katana`, `dalfox`
- **Binary & CTF:** `gdb`, `radare2`, `ghidra`, `binwalk`, `checksec`, `foremost`, `steghide`, `exiftool`, `zsteg`, `pwninit`
- **OSINT & Intelligence:** `exploitdb`, `kismet`, `sherlock`, `recon-ng`, `spiderfoot`, `social-analyzer`, `shodan-cli`, `censys-cli`, `pwned`
- **Cloud & Container:** `prowler`, `scout-suite`, `checkov`, `terrascan`, `kube-hunter`, `kube-bench`, `trivy`, `docker-bench-security`
- **Utilities:** Kali wordlists, `httpie`, Chrome/Chromium + driver, Python virtual environment with HexStrike requirements

Everything runs as `root` inside the container so tools that require raw sockets or privileged ports behave as expected.

---

## Manual Docker Build

For custom builds or when not using Docker Compose.

### 1. Build the Image

```bash
# From repository root
docker build -t hexstrike-ai:v6.0 -f docker/Dockerfile .

# With build arguments (optional)
docker build \
  --build-arg PYTHON_VERSION=3.11 \
  -t hexstrike-ai:v6.0 \
  -f docker/Dockerfile .

# View build progress with detailed output
docker build --progress=plain -t hexstrike-ai:v6.0 -f docker/Dockerfile .
```

### 2. Run the Container

**Basic Run:**
```bash
docker run --rm -it \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -p 8888:8888 \
  hexstrike-ai:v6.0
```

**With Volume Mounts:**
```bash
docker run --rm -it \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -p 8888:8888 \
  -v $(pwd)/scan-results:/opt/hexstrike/results \
  -v $(pwd)/logs:/opt/hexstrike/logs \
  hexstrike-ai:v6.0
```

**Detached Mode with Restart:**
```bash
docker run -d \
  --name hexstrike-mcp \
  --restart unless-stopped \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -p 8888:8888 \
  -v $(pwd)/scan-results:/opt/hexstrike/results \
  hexstrike-ai:v6.0
```

### 3. Container Management

```bash
# View running containers
docker ps

# View logs
docker logs -f hexstrike-mcp

# Execute commands inside container
docker exec -it hexstrike-mcp bash

# Stop container
docker stop hexstrike-mcp

# Remove container
docker rm hexstrike-mcp

# Remove image
docker rmi hexstrike-ai:v6.0
```

---

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

### Build Issues

**Problem**: Build fails with "command not found"
```bash
# Solution: Check tool installation in Dockerfile
docker build --progress=plain -t hexstrike-ai:v6.0 -f docker/Dockerfile .
# Review output for specific failing command
```

**Problem**: Build is very slow
```bash
# Solution: Use BuildKit for parallel builds
DOCKER_BUILDKIT=1 docker build -t hexstrike-ai:v6.0 -f docker/Dockerfile .
```

**Problem**: Out of disk space
```bash
# Solution: Clean Docker cache
docker system prune -a --volumes
```

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

### Performance Issues

**Problem**: Container using too much memory
```bash
# Check resource usage
docker stats hexstrike-mcp

# Adjust memory limits in docker-compose.yml:
# deploy:
#   resources:
#     limits:
#       memory: 4G
```

**Problem**: Slow scan performance
```bash
# Increase CPU allocation in docker-compose.yml:
# deploy:
#   resources:
#     limits:
#       cpus: '8.0'
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

### User Namespaces

Enable Docker user namespace remapping:

```bash
# /etc/docker/daemon.json
{
  "userns-remap": "default"
}
```

---

## Advanced Usage

### Custom Tool Installation

To add additional tools:

```dockerfile
# Create custom Dockerfile extending base image
FROM hexstrike-ai:v6.0

# Install custom tools
RUN apt-get update && \
    apt-get install -y custom-tool && \
    apt-get clean
```

### Multi-Stage Builds

For smaller final images:

```dockerfile
# Build stage
FROM hexstrike-ai:v6.0 AS builder
RUN go install github.com/example/tool@latest

# Runtime stage
FROM hexstrike-ai:v6.0
COPY --from=builder /root/go/bin/tool /usr/local/bin/
```

---

## Support

For issues or questions:

- **GitHub Issues**: https://github.com/0x4m4/hexstrike-ai/issues
- **Documentation**: https://github.com/0x4m4/hexstrike-ai
- **Discord**: https://discord.gg/BWnmrrSHbA

---

## Notes

- Some tools require elevated privileges or kernel capabilities
- Grant capabilities at runtime with `--cap-add=NET_RAW --cap-add=NET_ADMIN`
- Running with `--privileged` is **not recommended** for production
- The image includes 150+ security tools as documented in README.md
- Build time: ~10-15 minutes depending on system and network speed
- Final image size: ~1-1.5GB
