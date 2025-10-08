# ==============================================================================
# HexStrike AI MCP Server v6.0 - Docker Image (Multi-stage Build)
# ==============================================================================
# Stage A: Python 3.12 base to provide a clean CPython into Kali
# Stage B: Go builder for Go-based CLIs (produces static-ish binaries)
# Stage C: Rust builder for Rust-based CLIs (produces binaries)
# Stage D: Final runtime on Kali rolling with categorized phases (README-aligned)
# Repository: https://github.com/0x4m4/hexstrike-ai
# License: MIT
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage A: Python 3.12 Base (for prowler) 
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS python312-base

# ------------------------------------------------------------------------------
# Stage CM: CloudMapper builder (Python 3.10 + dedicated venv with pyjq)
# ------------------------------------------------------------------------------
FROM python:3.10-slim AS cloudmapper-builder

ENV CM_VENV=/opt/venvs/cloudmapper
WORKDIR /opt/hexstrike

# Install build prerequisites and jq development libraries for pyjq
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential autoconf automake libtool pkg-config \
      git curl ca-certificates \
      libjq-dev libonig-dev bison flex \
    && rm -rf /var/lib/apt/lists/*

# Create a dedicated virtual environment for CloudMapper
RUN python -m venv "$CM_VENV" \
 && "$CM_VENV/bin/pip" install --no-cache-dir -U pip setuptools wheel

# Fetch CloudMapper directly from upstream to avoid context COPY issues
RUN git clone --depth 1 https://github.com/duo-labs/cloudmapper.git /opt/hexstrike/tools/cloudmapper \
 && rm -rf /opt/hexstrike/tools/cloudmapper/.git

# Normalize requirement pins and install into the dedicated venv
RUN set -eux; \
  REQ=/opt/hexstrike/tools/cloudmapper/requirements.txt; \
  # Align matplotlib/numpy to versions compatible with Python 3.10
  sed -i \
    -e 's/^matplotlib==3\.4\.3$/matplotlib==3.7.5/' \
    -e 's/^numpy==1\.22\.0$/numpy>=1.23/' \
    "$REQ"; \
  # Drop typed-ast (not supported on Python ≥ 3.10)
  sed -i '/^typed-ast==/d' "$REQ"; \
  # Optionally bump pyjq to a newer compatible version if pinned
  sed -i 's/^pyjq==2\.4\.0$/pyjq==2\.6\.0/' "$REQ" || true; \
  # Install all dependencies in the CloudMapper venv
  "$CM_VENV/bin/pip" install --no-cache-dir --prefer-binary -r "$REQ"

# ------------------------------------------------------------------------------
# Stage B: Go Builder
#   Builds Go CLIs once and exports binaries under /out for the final image.
#   We use ephemeral GOMODCACHE/GOCACHE and wipe them in the same RUN to avoid
#   persisting large module/testdata blobs in the layer.
# ------------------------------------------------------------------------------
FROM golang:latest AS go-builder
ENV GO111MODULE=on \
    GOBIN=/out \
    GOPROXY=https://proxy.golang.org,direct \
    GOSUMDB=sum.golang.org \
    GOFLAGS=-trimpath

# Minimal toolchain for CGO builds (only for katana)
RUN set -eux; \
    mkdir -p "${GOBIN}" && \
    apt-get update && apt-get install -y --no-install-recommends build-essential pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Install Go tools that do not require CGO (single layer; then purge caches)
ENV CGO_ENABLED=0 \
    GOMODCACHE=/tmp/gomod \
    GOCACHE=/tmp/gocache
RUN set -eux; \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest && \
    go install -v github.com/hahwul/dalfox/v2@latest && \
    go install -v github.com/jaeles-project/jaeles@latest && \
    go install -v github.com/lc/gau/v2/cmd/gau@latest && \
    go install -v github.com/tomnomnom/waybackurls@latest && \
    go install -v github.com/tomnomnom/assetfinder@latest && \
    go install -v github.com/tomnomnom/anew@latest && \
    go install -v github.com/tomnomnom/qsreplace@latest && \
    # Clean Go build/module caches to keep the layer tiny
    go clean -cache -modcache || true; \
    rm -rf "${GOMODCACHE}" "${GOCACHE}" /go/pkg/mod /root/go/pkg/mod || true

# katana requires CGO (go-tree-sitter). Build in a separate RUN and purge caches.
ENV CGO_ENABLED=1 \
    GOMODCACHE=/tmp/gomod \
    GOCACHE=/tmp/gocache
RUN set -eux; \
    go install -v github.com/projectdiscovery/katana/cmd/katana@latest && \
    go clean -cache -modcache || true; \
    rm -rf "${GOMODCACHE}" "${GOCACHE}" /go/pkg/mod /root/go/pkg/mod || true

# ------------------------------------------------------------------------------
# Stage C: Rust Builder
#   Compiles Rust CLIs and exports binaries under /out for the final image.
# ------------------------------------------------------------------------------
FROM rust:latest AS rust-builder

# Ensure toolchain is present and create export directory
RUN set -eux; \
    rustc --version; cargo --version; \
    mkdir -p /out

# rustscan - Port scanner (Rust)
RUN set -eux; \
    cargo install --root /tmp --bins rustscan; \
    install -m 0755 /tmp/bin/rustscan /out/rustscan; \
    rm -rf /tmp/* ~/.cargo/registry ~/.cargo/git

# pwninit - CTF binary setup automation (Rust)
RUN set -eux; \
    cargo install --root /tmp --bins pwninit; \
    install -m 0755 /tmp/bin/pwninit /out/pwninit; \
    rm -rf /tmp/* ~/.cargo/registry ~/.cargo/git

# x8 - Hidden parameter discovery (Rust)
RUN set -eux; \
    git clone --depth 1 https://github.com/Sh1Yo/x8.git /tmp/x8; \
    cargo build --manifest-path /tmp/x8/Cargo.toml --release; \
    install -m 0755 /tmp/x8/target/release/x8 /out/x8; \
    rm -rf /tmp/x8 ~/.cargo/registry ~/.cargo/git

# ------------------------------------------------------------------------------
# Stage D: Final - Kali Linux + Python 3.12 + categorized tooling
# ------------------------------------------------------------------------------
FROM docker.io/kalilinux/kali-rolling:latest

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt/hexstrike

# Bring CPython 3.12 from Stage A (needed by prowler)
COPY --from=python312-base /usr/local/ /usr/local/
RUN ln -sf /usr/local/lib/libpython3.12.so.1.0 /usr/local/lib/libpython3.12.so && \
    ldconfig

# ==============================================================================
# Phase 1: Base System Packages
# ==============================================================================
# - curl - Data transfer for installers and health checks
# - wget - Alternative downloader
# - git - Clone upstream tools when needed
# - ca-certificates - TLS trust store for secure downloads
# - gnupg2, lsb-release - Repository key management and release info
# - xz-utils - XZ compression support (used by some installers)
# - httpie - HTTP client for diagnostics
# - wordlists - Common wordlists for SecOps
RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-utils \
        curl \
        wget \
        git \
        gnupg2 \
        lsb-release \
        xz-utils \
        ca-certificates \
        wordlists \
        httpie

# ==============================================================================
# Phase 2: Language Runtimes (runtime only; no compilers/dev headers here)
# ==============================================================================
# Runtimes used by the tooling (Go/Rust come from their dedicated builder stages)
# - Node.js + npm - Required by some OSINT and web tools
# - Java (JDK) - Required by certain binary analysis tools
# - Ruby - Required by WPScan and auxiliary gems
# - pipx - Isolated installer for Python CLIs (Checkov, Prowler, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
      nodejs \
      npm \
      default-jdk \
      ruby-full \
      pipx \
      python3-venv
ENV PIPX_DEFAULT_PYTHON=/usr/bin/python3

# ==============================================================================
# Phase 3: Python Virtual Environment
# ==============================================================================
ENV VIRTUAL_ENV=/opt/hexstrike/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN /usr/bin/python3 -m venv "$VIRTUAL_ENV" \
 && . "$VIRTUAL_ENV/bin/activate" \
 && pip install --no-cache-dir --upgrade pip setuptools wheel
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=120 \
    PIP_NO_PYTHON_VERSION_WARNING=1
ENV PATH="/root/.local/bin:${PATH}"

# ==============================================================================
# Phase 4: Core Python Dependencies (app)
# ==============================================================================
# Copy requirements.txt first for Docker layer caching optimization
COPY requirements.txt hexstrike_server.py hexstrike_mcp.py /opt/hexstrike/

# Build deps to compile native wheels (e.g., msgpack, netifaces) - removed in final cleanup
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      python3-dev

# Install core Python dependencies into virtual environment
RUN pip install --no-cache-dir -r /opt/hexstrike/requirements.txt

# ==============================================================================
# Phase 5: Cloud & Container Security (Python CLIs)
# ==============================================================================
# Install cloud and container security CLIs (order matches pipx install below)
# - ansible - Automation engine for configuration and orchestration
RUN apt-get install -y --no-install-recommends \
        ansible

# Install Python CLIs via pipx (official, isolated)
# - Checkov - IaC security scanning for Terraform/CloudFormation/Kubernetes
# - prowler - AWS/Azure/GCP security assessment with compliance checks (requires Python < 3.13)
# - ScoutSuite - Multi-cloud security auditing for AWS/Azure/GCP/Alibaba Cloud
# - kube-hunter - Kubernetes penetration testing (active/passive modes)
# - shodan - Official Shodan CLI (Python)
# - censys - Official Censys CLI (Python)
RUN pipx install --pip-args="--no-cache-dir --prefer-binary" checkov     && \
    pipx install --python /usr/local/bin/python3.12 --pip-args="--no-cache-dir --prefer-binary" prowler     && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" ScoutSuite  && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" kube-hunter && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" shodan      && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" censys

# Terrascan - Policy-as-code scanner
RUN set -eux; \
    curl -s https://api.github.com/repos/tenable/terrascan/releases/latest \
     | awk -F'"' '/browser_download_url/ && /Linux_x86_64\.tar\.gz/ {print $4; exit}' \
     | xargs -r curl -fsSL -o /tmp/terrascan.tgz; \
    tar -C /tmp -xzf /tmp/terrascan.tgz terrascan; \
    install /tmp/terrascan /usr/local/bin/terrascan; \
    rm -f /tmp/terrascan /tmp/terrascan.tgz

# OpenTofu (adds repo, installs tofu, and symlinks terraform)
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://get.opentofu.org/opentofu.gpg | tee /etc/apt/keyrings/opentofu.gpg >/dev/null && \
    curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg && \
    chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" > /etc/apt/sources.list.d/opentofu.list && \
    echo "deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" >> /etc/apt/sources.list.d/opentofu.list && \
    apt-get update && apt-get install -y --no-install-recommends tofu && \
    ln -sf /usr/bin/tofu /usr/local/bin/terraform

# AWS CLI v2 - Official installer
RUN cd /tmp && \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && \
    apt-get install -y --no-install-recommends unzip && \
    unzip -q awscliv2.zip && ./aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

# ==============================================================================
# Phase 6: Network & Reconnaissance Tools
# ==============================================================================
RUN apt-get install -y --no-install-recommends \
        nmap \
        masscan \
        autorecon \
        amass \
        subfinder \
        sublist3r \
        fierce \
        dnsenum \
        dnsrecon \
        theharvester \
        whois \
        dnsutils \
        bind9-host \
        responder \
        netexec \
        enum4linux-ng \
        enum4linux \
        nbtscan \
        arp-scan \
        samba-common-bin \
        smbclient

# rustscan - Port scanner (from Rust builder)
COPY --from=rust-builder /out/rustscan /usr/local/bin/rustscan

# ==============================================================================
# Phase 7: Web Application Security Tools
# ==============================================================================
# APT-delivered web tooling (explicit for reproducibility)
# - gobuster - Directory/DNS enumeration
# - feroxbuster - Recursive content discovery
# - ffuf - Fast web fuzzer
# - dotdotpwn - Path traversal fuzzer
# - xsser - XSS framework
# - wfuzz - Web application fuzzer
# - dirb - Web content scanner
# - dirsearch - Web path scanner
# - nikto - Web server scanner
# - sqlmap - SQL injection automation
# - wpscan - WordPress scanner
# - arjun - HTTP parameter discovery
# - paramspider - Parameter miner
# - hakrawler - Web endpoint crawler
# - wafw00f - WAF fingerprinting
# - whatweb - Web tech fingerprinting
# - burpsuite - Web security testing platform
# - zaproxy - OWASP ZAP scanner
RUN apt-get install -y --no-install-recommends \
        gobuster \
        feroxbuster \
        ffuf \
        dotdotpwn \
        xsser \
        wfuzz \
        dirb \
        dirsearch \
        nikto \
        sqlmap \
        wpscan \
        arjun \
        paramspider \
        hakrawler \
        wafw00f \
        whatweb \
        burpsuite \
        zaproxy

# Install Go-based reconnaissance & container utilities (ordered as below)
# - katana: Next-generation crawling and spidering (JavaScript-aware)
# - httpx: Fast HTTP probing and technology detection
# - nuclei: Template-driven vulnerability scanning (4000+ templates)
# - dalfox: Advanced DOM-aware XSS scanner
# - jaeles: Signature-based web vulnerability scanner
# - gau: Aggregate historical URLs (Wayback/Common Crawl)
# - waybackurls: Wayback Machine URL discovery
# - assetfinder: Subdomain/asset enumerator
# - anew: Append-only deduplication helper
# - qsreplace: Query parameter mutation utility
COPY --from=go-builder /out/* /usr/local/bin/

# x8 - Hidden parameter discovery (from Rust builder)
COPY --from=rust-builder /out/x8 /usr/local/bin/x8

# ==============================================================================
# Phase 8: Authentication & Password Security
# ==============================================================================
# Install password cracking and authentication testing tools
# - hydra: Network login cracker
# - john: Password cracker
# - hashcat: GPU-accelerated password recovery
# - medusa: Parallel brute-forcer
# - patator: Multi-purpose brute-forcer
# - evil-winrm: WinRM shell for Windows
# - hash-identifier: Hash type identification
# - hashid: Hash algorithm identifier
# - ophcrack: Windows password cracker
# - hashcat-utils: Utilities for hashcat
RUN apt-get install -y --no-install-recommends \
        hydra \
        john \
        hashcat \
        medusa \
        patator \
        evil-winrm \
        hash-identifier \
        hashid \
        ophcrack \
        hashcat-utils

# ==============================================================================
# Phase 9: Binary & Forensics Tools
# ==============================================================================
# Install binary analysis and forensics tooling referenced in README.md
RUN apt-get install -y --no-install-recommends \
        gdb \
        radare2 \
        ghidra \
        binwalk \
        checksec \
        foremost \
        steghide \
        exiftool \
        ropper \
        autopsy \
        sleuthkit \
        outguess \
        testdisk \
        scalpel \
        bulk-extractor \
        smbmap \
        zbar-tools \
        p7zip-full \
        apktool \
        android-tools-adb \
        binutils \
        xxd

# Python-based binary helpers (latest stable releases)
# - ropgadget: ROP/JOP gadget finder
# - volatility3: Next-generation memory forensics framework
# - uro: URL declutterer / deduplication utility
RUN pip install --no-cache-dir \
        ropgadget \
        volatility3 \
        uro

# pwninit - CTF binary setup automation
COPY --from=rust-builder /out/pwninit /usr/local/bin/pwninit

# zsteg - PNG/BMP steganography detection
# one_gadget - ROP gadget finder for GLIB
RUN gem install --no-document zsteg one_gadget

# HashPump: provide CLI wrapper via hashpumpy (PyPI)
RUN pip install --no-cache-dir hashpumpy && \
    printf '%s\n' '#!/usr/bin/env python3' \
'import argparse' \
'from hashpumpy import hashpump' \
'parser = argparse.ArgumentParser()' \
'parser.add_argument("-s","--signature", required=True)' \
'parser.add_argument("-d","--data", required=True)' \
'parser.add_argument("-k","--key_length", type=int, required=True)' \
'parser.add_argument("-a","--append_data", required=True)' \
'args = parser.parse_args()' \
'new_sig, new_msg = hashpump(args.signature, args.data, args.append_data, args.key_length)' \
'print(new_sig)' \
'print(new_msg)' \
> /usr/local/bin/hashpump && chmod +x /usr/local/bin/hashpump

# ==============================================================================
# Phase 10: OSINT & Intelligence Tools
# ==============================================================================
# Install OSINT tooling referenced in README.md and MCP routes
# - exploitdb: Exploit Database
# - kismet: Wireless network detector
# - sherlock: Username search across sites
# - recon-ng: Web recon framework
# - spiderfoot: OSINT automation
RUN apt-get install -y --no-install-recommends \
        exploitdb \
        kismet \
        sherlock \
        recon-ng \
        spiderfoot

# Install OSINT companion CLIs distributed via npm
# - social-analyzer: Social media analysis toolkit
# - pwned: Have I Been Pwned CLI
# - jwt-cracker: JWT cracking utility
# - graphql-playground-html: GraphQL Playground static server
# - graphql-voyager: GraphQL schema visualization
RUN npm install -g \
        social-analyzer \
        pwned \
        jwt-cracker \
        graphql-playground-html \
        graphql-voyager

# ==============================================================================
# Phase 11: Wireless & Packet Analysis
# ==============================================================================
# Install packet capture / 802.11 tooling used by network automation endpoints
# - wireshark: Network protocol analyzer
# - tshark: Terminal-based Wireshark
# - tcpdump: Packet capture utility
# - aircrack-ng: 802.11 WEP/WPA cracking
RUN apt-get install -y --no-install-recommends \
        wireshark \
        tshark \
        tcpdump \
        aircrack-ng

# ==============================================================================
# Phase 12: Exploitation Frameworks
# ==============================================================================
RUN apt-get install -y --no-install-recommends \
        metasploit-framework

# ==============================================================================
# Phase 13: Runtime Security Agents
# ==============================================================================
# Install Falco (extract files without DKMS/systemd during build)
RUN install -d -m 0755 /usr/share/keyrings && \
    curl -fsSL https://falco.org/repo/falcosecurity-packages.asc \
      | gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" \
      > /etc/apt/sources.list.d/falcosecurity.list && \
    apt-get update -y && \
    mkdir -p /tmp/falco && cd /tmp/falco && \
    apt-get download falco && \
    dpkg-deb -x ./falco_*.deb / && \
    cd / && rm -rf /tmp/falco

# Newman (Postman CLI)
RUN npm install -g newman

# ==============================================================================
# Phase 14: Browser Agent Requirements
# ==============================================================================
RUN apt-get install -y --no-install-recommends \
      chromium \
      chromium-driver

# ==============================================================================
# Phase 15: Security Tool Repositories & Wrappers
#   - CloudMapper code and venv are copied from the dedicated builder stage
#   - Pacu via pipx on CPython 3.12 to avoid Python 3.13 C-API build issues
#   - Keep other tools cloned from upstream (jwt_tool, libc-database, peda, stegsolve)
# ==============================================================================

# Bring CloudMapper code and its dedicated venv from the builder stage
COPY --from=cloudmapper-builder /opt/venvs/cloudmapper /opt/venvs/cloudmapper
COPY --from=cloudmapper-builder /opt/hexstrike/tools/cloudmapper /opt/hexstrike/tools/cloudmapper

# Install system deps for Pacu (cffi may require libffi) and jq CLI; then install Pacu via pipx on Python 3.12
RUN apt-get update && apt-get install -y --no-install-recommends jq libffi-dev \
 && pipx install --python /usr/local/bin/python3.12 git+https://github.com/RhinoSecurityLabs/pacu.git

# Clone remaining tool repositories
RUN mkdir -p /opt/hexstrike/tools && \
    git clone --depth 1 https://github.com/ticarpi/jwt_tool.git /opt/hexstrike/tools/jwt_tool && \
    rm -rf /opt/hexstrike/tools/jwt_tool/.git && \
    git clone --depth 1 https://github.com/niklasb/libc-database.git /opt/hexstrike/tools/libc-database && \
    rm -rf /opt/hexstrike/tools/libc-database/.git && \
    git clone --depth 1 https://github.com/longld/peda.git /root/peda && \
    rm -rf /root/peda/.git && \
    mkdir -p /opt/stegsolve && \
    curl -fsSL -o /opt/stegsolve/stegsolve.jar https://github.com/Giotino/stegsolve/releases/download/v1.4/StegSolve-1.4.jar && \
    chmod 644 /opt/stegsolve/stegsolve.jar && \
    ln -s /opt/hexstrike/tools/libc-database /opt/libc-database && \
    ln -s /opt/hexstrike/tools/jwt_tool /opt/jwt_tool

RUN pip install --no-cache-dir -r /opt/hexstrike/tools/jwt_tool/requirements.txt

# Convenience entrypoints expected by MCP routes/health checks
RUN printf '#!/bin/bash\n/opt/venvs/cloudmapper/bin/python /opt/hexstrike/tools/cloudmapper/cloudmapper.py "$@"\n' > /usr/local/bin/cloudmapper && \
    chmod +x /usr/local/bin/cloudmapper && \
    mkdir -p /opt/burpsuite && \
    if [ -f /usr/share/burpsuite/burpsuite.jar ]; then ln -sf /usr/share/burpsuite/burpsuite.jar /opt/burpsuite/burpsuite.jar; fi && \
    ln -sf /usr/local/bin/newman /usr/local/bin/postman && \
    printf '#!/bin/bash\nnpx --yes graphql-playground-html "$@"\n' > /usr/local/bin/graphql-playground && \
    chmod +x /usr/local/bin/graphql-playground && \
    printf '#!/bin/bash\nnpx --yes graphql-voyager "$@"\n' > /usr/local/bin/graphql-voyager && \
    chmod +x /usr/local/bin/graphql-voyager && \
    printf '#!/usr/bin/env python3\nimport json,sys\n\nif len(sys.argv) < 2:\n    print("Usage: api-schema-analyzer <schema-file>")\n    sys.exit(1)\npath = sys.argv[1]\nwith open(path, "r", encoding="utf-8") as f:\n    data = json.load(f)\npaths = data.get(\"paths\", {})\nprint(f\"Endpoints: {len(paths)}\")\nfor route, methods in paths.items():\n    verbs = \", \".join(m.upper() for m in methods.keys())\n    print(f\"- {route}: {verbs}\")\n' > /usr/local/bin/api-schema-analyzer && \
    chmod +x /usr/local/bin/api-schema-analyzer

# ==============================================================================
# Phase 16: Cloud & Container Security Binaries
# ==============================================================================
# Trivy - Container vulnerability scanner
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sh -s -- -b /usr/local/bin

# docker-bench-security - Docker daemon configuration audit
RUN mkdir -p /opt/hexstrike/tools && \
    git clone --depth 1 https://github.com/docker/docker-bench-security.git /opt/hexstrike/tools/docker-bench-security && \
    rm -rf /opt/hexstrike/tools/docker-bench-security/.git && \
    printf '#!/bin/bash\nset -e\ncd /opt/hexstrike/tools/docker-bench-security\nexec ./docker-bench-security.sh "$@"\n' > /usr/local/bin/docker-bench-security && \
    chmod +x /usr/local/bin/docker-bench-security

# - clairctl: Container vulnerability assessment CLI (only amd64/arm64)
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) url="https://github.com/quay/clair/releases/latest/download/clairctl-linux-amd64";; \
      arm64) url="https://github.com/quay/clair/releases/latest/download/clairctl-linux-arm64";; \
      *) echo "unsupported arch for clairctl: $arch"; exit 1;; \
    esac; \
    curl -fsSL "$url" -o /usr/local/bin/clairctl; \
    chmod 0755 /usr/local/bin/clairctl; \
    /usr/local/bin/clairctl --version || true

# ==============================================================================
# Phase 17: Image Cleanup
# ==============================================================================
RUN apt-get purge -y --auto-remove build-essential python3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 18: Runtime Configuration
# ==============================================================================

# Expose MCP server port
EXPOSE 8888

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8888/health || exit 1

# ==============================================================================
# Phase 19: Startup
# ==============================================================================
# Start HexStrike MCP server using virtual environment Python
CMD ["python3", "hexstrike_server.py"]
