# ==============================================================================
# HexStrike AI MCP Server v6.0 - Docker Image (Multi-stage Build)
# ==============================================================================
# Repository: https://github.com/0x4m4/hexstrike-ai
# License: MIT
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage A: Python 3.12 Base (for prowler and Pacu) 
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS python312-base

# ------------------------------------------------------------------------------
# Stage B: CloudMapper builder (Python 3.10 + dedicated venv with pyjq)
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
    -e 's/^matplotlib==3\.4\.3$/matplotlib==3\.7\.5/' \
    -e 's/^numpy==1\.22\.0$/numpy>=1\.23/' \
    "$REQ"; \
  # Drop typed-ast (not supported on Python ≥ 3.10)
  sed -i '/^typed-ast==/d' "$REQ"; \
  # Optionally bump pyjq to a newer compatible version if pinned
  sed -i 's/^pyjq==2\.4\.0$/pyjq==2\.6\.0/' "$REQ"; \
  # Install all dependencies in the CloudMapper venv
  "$CM_VENV/bin/pip" install --no-cache-dir --prefer-binary -r "$REQ"

# ------------------------------------------------------------------------------
# Stage C: Node.js 18 Builder for insomnia-inso (isolated runtime)
# ------------------------------------------------------------------------------
FROM node:18-bullseye AS insomnia-node18-builder

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_PREFIX=/opt/insomnia

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
        python3-pip \
        python3-setuptools \
        libcurl4-openssl-dev \
        pkg-config \
        git \
        jq \
    && python3 -m pip install --no-cache-dir gyp-next

# Install insomnia CLI plus supporting reconnaissance tools (official releases)
RUN npm install -g --build-from-source insomnia-inso \
    && npm cache clean --force

RUN mkdir -p /opt/insomnia-artifacts/node18 && \
    cp -a /usr/local/bin /opt/insomnia-artifacts/node18/bin && \
    cp -a /usr/local/lib /opt/insomnia-artifacts/node18/lib && \
    cp -a /usr/local/include /opt/insomnia-artifacts/node18/include && \
    cp -a /usr/local/share /opt/insomnia-artifacts/node18/share && \
    cp -a /opt/insomnia /opt/insomnia-artifacts/insomnia

# ------------------------------------------------------------------------------
# Stage D: Final - Kali Linux + All Tools & Runtimes
# ------------------------------------------------------------------------------
FROM docker.io/kalilinux/kali-rolling:latest

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt/hexstrike

# Copy Python 3.12 runtime from Stage A (needed by prowler and Pacu)
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
        httpie \
        jq

# ==============================================================================
# Phase 2: Language Runtimes and Build Tools
# ==============================================================================
# - Node.js + npm - Required by some OSINT and web tools
# - Java (JDK) - Required by certain binary analysis tools
# - Ruby - Required by WPScan and auxiliary gems
# - pipx - Isolated installer for Python CLIs
RUN apt-get update && apt-get install -y --no-install-recommends \
        nodejs \
        npm \
        default-jdk \
        ruby-full \
        pipx \
        python3-venv \
        python3-pip \
        build-essential \
        python3-dev \
        g++

ENV PIPX_DEFAULT_PYTHON=/usr/bin/python3
ENV npm_config_python=/usr/bin/python3
ENV PYTHON=/usr/bin/python3

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
ENV PATH="${PATH}:/root/.local/bin"

# ==============================================================================
# Phase 4: Core Python Dependencies and MCP Server
# ==============================================================================
# Copy requirements.txt first for Docker layer caching optimization
COPY requirements.txt hexstrike_server.py hexstrike_mcp.py /opt/hexstrike/

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
# - prowler - AWS/Azure/GCP security assessment with compliance checks
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
    url="$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest \
      | awk -F'"' '/browser_download_url/ && /Linux_[xX]86_64\.tar\.gz/ {print $4; exit}')"; \
    curl -fsSL "$url" -o /tmp/terrascan.tgz; \
    tar -C /tmp -xzf /tmp/terrascan.tgz terrascan; \
    install /tmp/terrascan /usr/local/bin/terrascan; \
    rm -f /tmp/terrascan /tmp/terrascan.tgz

# OpenTofu - Terraform-compatible IaC tool (APT repository)
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

# RustScan - The modern port scanner
RUN set -eux; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  url="$(curl -fsSL https://api.github.com/repos/bee-san/RustScan/releases/latest \
         | jq -r '.assets[]?.browser_download_url | select(endswith("rustscan.deb.zip"))' | head -n1)"; \
  [ -n "$url" ] || { echo "rustscan.deb.zip asset not found in latest release"; exit 1; }; \
  curl -fsSL -o rustscan.deb.zip "$url"; \
  apt-get update && apt-get install -y --no-install-recommends unzip; \
  unzip -q rustscan.deb.zip; \
  deb="$(printf '%s\n' rustscan*.deb | head -n1)"; \
  dpkg -i "$deb" || apt-get -f install -y; \
  cd /; rm -rf "$tmp"

# ==============================================================================
# Phase 7: Web Application Security Tools
# ==============================================================================
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

# - katana: Next-generation crawler & spider
RUN set -euo pipefail; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  j="$(curl -fsSL https://api.github.com/repos/projectdiscovery/katana/releases/latest)"; \
  tag="$(printf '%s' "$j" | jq -r '.tag_name')"; \
  asset="$(printf '%s' "$j" | jq -r '.assets[]?.name | select(test("^katana_[0-9.]+_linux_amd64\\.zip$"))' | head -n1)"; \
  [ -n "$asset" ] || { echo 'katana: linux_amd64 zip asset not found'; exit 1; }; \
  curl -fsSL -o "$asset" "https://github.com/projectdiscovery/katana/releases/download/${tag}/${asset}"; \
  unzip -p "$asset" "*/katana" > katana 2>/dev/null || unzip -p "$asset" "katana" > katana; \
  chmod 0755 katana; install -m 0755 katana /usr/local/bin/katana; \
  cd /; rm -rf "$tmp"

# - httpx: Fast HTTP probing with tech detection
RUN set -euo pipefail; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  j="$(curl -fsSL https://api.github.com/repos/projectdiscovery/httpx/releases/latest)"; \
  tag="$(printf '%s' "$j" | jq -r '.tag_name')"; \
  asset="$(printf '%s' "$j" | jq -r '.assets[]?.name | select(test("^httpx_[0-9.]+_linux_amd64\\.zip$"))' | head -n1)"; \
  [ -n "$asset" ] || { echo 'httpx: linux_amd64 zip asset not found'; exit 1; }; \
  curl -fsSL -o "$asset" "https://github.com/projectdiscovery/httpx/releases/download/${tag}/${asset}"; \
  unzip -p "$asset" "*/httpx" > httpx 2>/dev/null || unzip -p "$asset" "httpx" > httpx; \
  chmod 0755 httpx; install -m 0755 httpx /usr/local/bin/httpx; \
  cd /; rm -rf "$tmp"

# - nuclei: Template-driven vulnerability scanner
RUN set -euo pipefail; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  j="$(curl -fsSL https://api.github.com/repos/projectdiscovery/nuclei/releases/latest)"; \
  tag="$(printf '%s' "$j" | jq -r '.tag_name')"; \
  asset="$(printf '%s' "$j" | jq -r '.assets[]?.name | select(test("^nuclei_[0-9.]+_linux_amd64\\.zip$"))' | head -n1)"; \
  [ -n "$asset" ] || { echo 'nuclei: linux_amd64 zip asset not found'; exit 1; }; \
  curl -fsSL -o "$asset" "https://github.com/projectdiscovery/nuclei/releases/download/${tag}/${asset}"; \
  unzip -p "$asset" "*/nuclei" > nuclei 2>/dev/null || unzip -p "$asset" "nuclei" > nuclei; \
  chmod 0755 nuclei; install -m 0755 nuclei /usr/local/bin/nuclei; \
  cd /; rm -rf "$tmp"

# dalfox - Fast XSS scanner
RUN set -euo pipefail; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  j="$(curl -fsSL https://api.github.com/repos/hahwul/dalfox/releases/latest)"; \
  tag="$(printf '%s' "$j" | jq -r '.tag_name')"; \
  [ -n "$tag" ]; \
  asset="dalfox-linux-amd64.tar.gz"; \
  curl -fsSL -o "$asset" "https://github.com/hahwul/dalfox/releases/download/${tag}/${asset}"; \
  tar -xOzf "$asset" dalfox-linux-amd64 > dalfox; \
  install -m 0755 dalfox /usr/local/bin/dalfox; \
  cd /; rm -rf "$tmp"

# - jaeles: Signature-based web vulnerability scanner
RUN set -euo pipefail; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  j="$(curl -fsSL https://api.github.com/repos/jaeles-project/jaeles/releases/latest)"; \
  tag="$(printf '%s' "$j" | jq -r '.tag_name')"; \
  asset="$(printf '%s' "$j" | jq -r '.assets[]?.name | select(test("^jaeles-.*-linux\\.zip$"))' | head -n1)"; \
  [ -n "$asset" ] || { echo 'jaeles: linux zip asset not found'; exit 1; }; \
  curl -fsSL -o "$asset" "https://github.com/jaeles-project/jaeles/releases/download/${tag}/${asset}"; \
  unzip -p "$asset" "*/jaeles" > jaeles 2>/dev/null || unzip -p "$asset" "jaeles" > jaeles; \
  chmod 0755 jaeles; install -m 0755 jaeles /usr/local/bin/jaeles; \
  cd /; rm -rf "$tmp"

# - x8: Fast XSS scanner
RUN set -euo pipefail; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  j="$(curl -fsSL https://api.github.com/repos/Sh1Yo/x8/releases/latest)"; \
  tag="$(printf '%s' "$j" | jq -r '.tag_name')"; \
  asset="$(printf '%s' "$j" | jq -r '.assets[]?.name | select(. == "x86_64-linux-x8.gz")' | head -n1)"; \
  [ -n "$asset" ] || { echo 'x8: x86_64-linux-x8.gz not found'; exit 1; }; \
  curl -fsSL -o "$asset" "https://github.com/Sh1Yo/x8/releases/download/${tag}/${asset}"; \
  gzip -dc "$asset" > x8; \
  chmod 0755 x8; install -m 0755 x8 /usr/local/bin/x8; \
  cd /; rm -rf "$tmp"

# - gau: GetAllUrls - URL discovery from AlienVault, Wayback Machine, Common Crawl, and URLScan.io
RUN set -euo pipefail; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  j="$(curl -fsSL https://api.github.com/repos/lc/gau/releases/latest)"; \
  tag="$(printf '%s' "$j" | jq -r '.tag_name')"; \
  asset="$(printf '%s' "$j" | jq -r '.assets[]?.name | select(test("^gau_[0-9.]+_linux_amd64\\.tar\\.gz$"))' | head -n1)"; \
  [ -n "$asset" ] || { echo 'gau: linux_amd64 tar.gz asset not found'; exit 1; }; \
  curl -fsSL -o "$asset" "https://github.com/lc/gau/releases/download/${tag}/${asset}"; \
  # Archive is expected to contain a single file named "gau"
  tar -xOzf "$asset" gau > gau; \
  install -m 0755 gau /usr/local/bin/gau; \
  cd /; rm -rf "$tmp"


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
# - pwntools: CTF framework and exploit development library
RUN pip install --no-cache-dir \
        ropgadget \
        volatility3 \
        uro \
        pwntools

# pwninit - CTF binary setup automation (official release binary)
RUN set -eux; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  json="$(curl -fsSL https://api.github.com/repos/io12/pwninit/releases/latest)"; \
  url="$(printf '%s\n' "$json" | jq -r '.assets[]?.browser_download_url' | grep -E '/pwninit($|[^/]*$)' | head -n1)"; \
  [ -n "$url" ] || { echo "No binary asset for pwninit latest"; exit 1; }; \
  curl -fsSL -o pwninit "$url"; \
  chmod +x pwninit; install -m 0755 pwninit /usr/local/bin/pwninit; \
  cd /; rm -rf "$tmp"

# zsteg - PNG/BMP steganography detection
# one_gadget - ROP gadget finder for glibc
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
# - maltego: Graphical link analysis tool
RUN apt-get install -y --no-install-recommends \
        exploitdb \
        kismet \
        sherlock \
        recon-ng \
        spiderfoot \
        maltego

# Install OSINT companion CLIs via npm (Node.js LTS runtime)
# - social-analyzer: Social media analysis toolkit
# - pwned: Have I Been Pwned CLI
# - graphql-inspector: GraphQL diffing/audit utility
# - jwt-cracker: JWT cracking utility
# - graphql-playground-html / graphql-voyager: GraphQL tooling
# - newman: Postman CLI
RUN npm install -g \
        social-analyzer \
        pwned \
        graphql-inspector \
        jwt-cracker \
        graphql-playground-html \
        graphql-voyager \
        newman

# GitHub releases for tomnomnom tools
# - anew: Append-only unique line filter
# - qsreplace: Query string replacement tool
# - waybackurls: Fetch URLs from the Wayback Machine
# - assetfinder: Subdomain discovery tool
RUN set -eux; \
  tmp="$(mktemp -d)"; cd "$tmp"; \
  for repo in tomnomnom/anew tomnomnom/qsreplace tomnomnom/waybackurls; do \
    name="${repo##*/}"; \
    json="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest")"; \
    url="$(printf '%s' "$json" | jq -r '.assets[]?.browser_download_url' | grep -E -- '-linux-amd64($|.*\.(tgz|tar\.gz|zip)$)' | head -n1)"; \
    [ -n "$url" ] || { echo "No linux-amd64 asset for ${repo} latest"; exit 1; }; \
    file="${url##*/}"; curl -fsSL -o "$file" "$url"; \
    case "$file" in \
      *.tgz|*.tar.gz) tar -xzf "$file" ;; \
      *.zip) apt-get update && apt-get install -y --no-install-recommends unzip && unzip -q "$file" ;; \
      *) : ;; \
    esac; \
    bin_path="$(find . -type f -perm -111 -name "${name}*" | head -n1)"; \
    [ -n "$bin_path" ] || bin_path="./$name"; \
    [ -f "$bin_path" ] || bin_path="$(find . -maxdepth 1 -type f -perm -111 | head -n1)"; \
    [ -n "$bin_path" ] || { echo "No executable found for ${repo}"; exit 1; }; \
    install -m 0755 "$bin_path" "/usr/local/bin/$name"; \
    rm -rf ./*; \
  done; \
  # assetfinder: /releases/latest may return 404 → use /releases (first item)
  repo="tomnomnom/assetfinder"; name="assetfinder"; \
  json="$(curl -fsSL "https://api.github.com/repos/${repo}/releases")"; \
  url="$(printf '%s' "$json" | jq -r '.[0].assets[]?.browser_download_url' | grep -E -- '-linux-amd64($|.*\.(tgz|tar\.gz|zip)$)' | head -n1)"; \
  [ -n "$url" ] || { echo "No linux-amd64 asset for ${repo}"; exit 1; }; \
  file="${url##*/}"; curl -fsSL -o "$file" "$url"; \
  case "$file" in \
    *.tgz|*.tar.gz) tar -xzf "$file" ;; \
    *.zip) apt-get update && apt-get install -y --no-install-recommends unzip && unzip -q "$file" ;; \
    *) : ;; \
  esac; \
  bin_path="$(find . -type f -perm -111 -name "${name}*" | head -n1)"; \
  [ -n "$bin_path" ] || bin_path="./$name"; \
  [ -f "$bin_path" ] || bin_path="$(find . -maxdepth 1 -type f -perm -111 | head -n1)"; \
  [ -n "$bin_path" ] || { echo "No executable found for ${repo}"; exit 1; }; \
  install -m 0755 "$bin_path" "/usr/local/bin/$name"; \
  cd /; rm -rf "$tmp"

# Bundle isolated Node.js 18 runtime for insomnia-inso only
COPY --from=insomnia-node18-builder /opt/insomnia-artifacts/node18 /opt/insomnia-node18
COPY --from=insomnia-node18-builder /opt/insomnia-artifacts/insomnia /opt/insomnia

# ==============================================================================
# Phase 11: Wireless & Packet Analysis
# ==============================================================================
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
# - metasploit-framework: Penetration testing framework
RUN apt-get install -y --no-install-recommends \
        metasploit-framework

# ==============================================================================
# Phase 13: Runtime Security Agents
# ==============================================================================
# - falco: Runtime security monitoring
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

# ==============================================================================
# Phase 14: Browser Agent Requirements
# ==============================================================================
# - chromium & chromium-driver: Headless browser and WebDriver
RUN apt-get install -y --no-install-recommends \
      chromium \
      chromium-driver

# ==============================================================================
# Phase 15: Security Tool Repositories & Wrappers
#   - CloudMapper code and venv are copied from the dedicated builder stage
#   - Pacu via pipx on CPython 3.12 to avoid Python 3.13 C-API build issues
# ==============================================================================
# Bring CloudMapper code and its dedicated venv from the builder stage
COPY --from=cloudmapper-builder /opt/venvs/cloudmapper /opt/venvs/cloudmapper
COPY --from=cloudmapper-builder /opt/hexstrike/tools/cloudmapper /opt/hexstrike/tools/cloudmapper

# Install system deps for Pacu (cffi may require libffi) and jq CLI; then install Pacu via pipx on Python 3.12
RUN apt-get install -y --no-install-recommends libffi-dev \
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
    /usr/local/bin/clairctl --version

# kube-bench - CIS Kubernetes benchmark auditing (official release archive)
RUN set -eux; \
    tmp=$(mktemp -d); cd "$tmp"; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) suffix="amd64";; \
      arm64) suffix="arm64";; \
      *) echo "unsupported arch for kube-bench: $arch"; exit 1;; \
    esac; \
    tag=$(curl -fsSL https://api.github.com/repos/aquasecurity/kube-bench/releases/latest | jq -r '.tag_name'); \
    file="kube-bench_${tag#v}_linux_${suffix}.tar.gz"; \
    curl -fsSL -o kube-bench.tgz "https://github.com/aquasecurity/kube-bench/releases/download/${tag}/${file}"; \
    tar -xzf kube-bench.tgz; \
    install -m 0755 kube-bench /usr/local/bin/kube-bench; \
    cd /; rm -rf "$tmp"

# ==============================================================================
# Phase 17: MCP Entry Points & Minimal Wrappers
# ==============================================================================
RUN set -eux; \
    # CloudMapper wrapper: ensure execution via its dedicated venv
    printf '#!/bin/bash\n/opt/venvs/cloudmapper/bin/python /opt/hexstrike/tools/cloudmapper/cloudmapper.py "$@"\n' \
      > /usr/local/bin/cloudmapper && chmod +x /usr/local/bin/cloudmapper && \
    # Insomnia CLI wrapper: run with isolated Node 18 runtime
    printf '#!/bin/bash\nPATH=/opt/insomnia-node18/bin:$PATH NODE_PATH=/opt/insomnia/lib/node_modules exec /opt/insomnia/bin/inso "$@"\n' \
      > /usr/local/bin/insomnia && chmod +x /usr/local/bin/insomnia && \
    # StegSolve wrapper: run jar with Java
    printf '#!/bin/bash\nexec java -jar /opt/stegsolve/stegsolve.jar "$@"\n' \
      > /usr/local/bin/stegsolve && chmod +x /usr/local/bin/stegsolve && \
    # JWT analyzer convenience wrapper
    printf '#!/bin/bash\nexec python3 /opt/hexstrike/tools/jwt_tool/jwt_tool.py "$@"\n' \
      > /usr/local/bin/jwt-analyzer && chmod +x /usr/local/bin/jwt-analyzer && \
    # API schema analyzer helper (minimal, prints endpoints + verbs)
    printf '#!/usr/bin/env python3\nimport json,sys\nif len(sys.argv)<2:\n print("Usage: api-schema-analyzer <schema-file>"); sys.exit(1)\npath=sys.argv[1]\nwith open(path,"r",encoding="utf-8") as h:\n data=json.load(h)\npaths=data.get("paths",{})\nprint(f"Endpoints: {len(paths)}")\nfor route,methods in paths.items():\n verbs=\", \".join(m.upper() for m in methods.keys())\n print(f\"- {route}: {verbs}\")\n' \
      > /usr/local/bin/api-schema-analyzer && chmod +x /usr/local/bin/api-schema-analyzer && \
    # GraphQL helpers via npx
    printf '#!/bin/bash\nexec npx --yes graphql-playground-html "$@"\n' \
      > /usr/local/bin/graphql-playground && chmod +x /usr/local/bin/graphql-playground && \
    printf '#!/bin/bash\nexec npx --yes graphql-voyager "$@"\n' \
      > /usr/local/bin/graphql-voyager && chmod +x /usr/local/bin/graphql-voyager && \
    \
    printf '#!/usr/bin/env python3\nimport runpy,sys\nsys.argv=[\"patator\"]+sys.argv[1:]\nrunpy.run_path(\"/usr/share/patator/patator.py\", run_name=\"__main__\")\n' \
      > /usr/local/bin/patator && chmod +x /usr/local/bin/patator && \
    printf '#!/usr/bin/env node\nrequire(\"/usr/lib/node_modules/social-analyzer/dist/index.js\");\n' \
      > /usr/local/bin/social-analyzer && chmod +x /usr/local/bin/social-analyzer && \
    \
    # Volatility name variants expected by the server
    printf '#!/bin/bash\nexec python3 -m volatility3 "$@"\n' \
      > /usr/local/bin/vol.py && chmod +x /usr/local/bin/vol.py && \
    printf '#!/bin/bash\nexec python3 -m volatility3 "$@"\n' \
      > /usr/local/bin/volatility && chmod +x /usr/local/bin/volatility && \
    ln -sf /opt/hexstrike/venv/bin/vol             /usr/local/bin/volatility3 && \
    ln -sf /opt/hexstrike/venv/bin/vol             /usr/local/bin/vol && \
    \
    # --- Compatibility aliases required by hexstrike_server.py ---
    ln -sf /usr/bin/searchsploit                   /usr/local/bin/exploit-db && \
    ln -sf /usr/local/bin/newman                   /usr/local/bin/postman && \
    ln -sf /usr/bin/http                           /usr/local/bin/httpie && \
    ln -sf /usr/local/bin/graphql-inspector        /usr/local/bin/graphql-scanner && \
    ln -sf /usr/bin/tsk_loaddb                     /usr/local/bin/sleuthkit && \
    ln -sf /usr/bin/msfconsole                     /usr/local/bin/metasploit && \
    ln -sf /usr/local/bin/pwned                    /usr/local/bin/have-i-been-pwned && \
    ln -sf /usr/local/bin/clairctl                 /usr/local/bin/clair && \
    ln -sf /usr/bin/bulk_extractor                 /usr/local/bin/bulk-extractor && \
    ln -sf /usr/local/bin/one_gadget               /usr/local/bin/one-gadget && \
    ln -sf /root/.local/bin/censys                 /usr/local/bin/censys-cli && \
    ln -sf /root/.local/bin/shodan                 /usr/local/bin/shodan-cli && \
    ln -sf /opt/hexstrike/tools/libc-database/find /usr/local/bin/libc-database && \
    ln -sf /opt/hexstrike/venv/bin/ROPgadget       /usr/local/bin/ropgadget && \
    ln -sf /opt/hexstrike/venv/bin/pwn             /usr/local/bin/pwntools && \
    ln -sf /root/.local/bin/scout                  /usr/local/bin/scout-suite && \
    ln -sf /usr/bin/evil-winrm                     /usr/local/bin/evil-winrm && \
    ln -sf /usr/bin/maltego                        /usr/local/bin/maltego && \
    \
    # hashcat-utils binary does not exist. Provide a real entrypoint name the server checks
    printf '#!/bin/bash\n# This launcher exists because the Debian/Kali package \"hashcat-utils\" ships multiple executables (e.g., cap2hccapx),\n# but no single binary literally named \"hashcat-utils\". The server health-check expects that name.\n# We delegate to a real tool from the suite so the check is truthful; if tools are missing, this fails naturally.\nexec cap2hccapx \"$@\"\n' \
      > /usr/local/bin/hashcat-utils && chmod +x /usr/local/bin/hashcat-utils

# ==============================================================================
# Phase 18: Image Cleanup
# ==============================================================================
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 19: Runtime Configuration
# ==============================================================================

# Expose MCP server port
EXPOSE 8888

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8888/health || exit 1

# Start HexStrike MCP server using virtual environment Python
CMD ["python3", "hexstrike_server.py"]
