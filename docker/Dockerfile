# ==============================================================================
# HexStrike AI MCP Server v6.0 - Docker Image (Multi-stage Build)
# ==============================================================================
# Stage 1: Official Python 3.12 image
# Stage 2: Kali Linux Rolling (includes 150+ pre-installed security tools)
# Repository: https://github.com/0x4m4/hexstrike-ai
# License: MIT
# ==============================================================================

# ==============================================================================
# Stage 1: Python 3.12 Base
# ==============================================================================
FROM python:3.12-slim AS python-base

# ==============================================================================
# Stage 2: Kali Linux with Python 3.12
# ==============================================================================
FROM docker.io/kalilinux/kali-rolling:latest

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /opt/hexstrike

# ==============================================================================
# Copy Python 3.12 from Stage 1
# Latest stable needed for prowler compatibility is 3.12
# ==============================================================================
# (Adjustment) Copy the whole /usr/local to avoid missing CPython components
COPY --from=python-base /usr/local/ /usr/local/

RUN ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python && \
    ln -sf /usr/local/bin/pip3.12 /usr/local/bin/pip3 && \
    ln -sf /usr/local/bin/pip3.12 /usr/local/bin/pip && \
    ln -sf /usr/local/lib/libpython3.12.so.1.0 /usr/local/lib/libpython3.12.so && \
    ldconfig

# (Adjustment) Ensure Python runtime libs on Kali
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libexpat1 libsqlite3-0 libbz2-1.0 libgdbm6 libncursesw6 libreadline8 \
        libffi8 liblzma5 libssl3 libuuid1 tk

# ==============================================================================
# Phase 1: Base System Packages
# ==============================================================================
# Update package lists and install core system utilities
# Install core utilities required for tool installation
RUN apt-get install -y --no-install-recommends \
        apt-utils \
        curl \
        wget \
        git \
        gnupg2 \
        lsb-release \
        software-properties-common \
        build-essential \
        xz-utils \
        uuid-dev \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libffi-dev \
        liblzma-dev \
        libgdbm-dev \
        libnss3-dev \
        tk-dev \
        ca-certificates \
        wordlists \
        httpie

# ==============================================================================
# Phase 2: Language Runtimes & Compilers
# ==============================================================================
# Install language runtimes required by various security tools
# - Python: Primary language for HexStrike and many security tools
# - Go: Required for tools like nuclei, httpx, subfinder, katana
# - Node.js/npm: Required for social-analyzer, shodan-cli, censys-cli, and pwned
# - Java: Required for some binary analysis tools
# - Ruby: Required for wpscan and other tools
# - Rust: Required for: rustscan, feroxbuster, pwninit, x8
# - Build tools: Provided via build-essential (gcc, g++, make)

# Install Rust and Cargo using official installer for latest version
ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH="$CARGO_HOME/bin:/root/go/bin:$PATH"
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# Install language runtimes required by various security tools
# - python3: CPython runtime for system packages
# - python3-pip: Python package manager
# - python3-venv: Virtual environments support
# - python3-dev: Python headers for building native extensions
# - pipx: Isolated CLI installs for Python tools
# - golang: Go toolchain for Go-based security tools
# - nodejs/npm: Node.js runtime and npm for JS-based tools
# - default-jdk: Java Development Kit for JVM-based tools
# - ruby-full: Ruby and gems for Ruby-based tools
# - autoconf/automake/pkg-config: build toolchain helpers
RUN apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        pipx \
        golang \
        nodejs \
        npm \
        default-jdk \
        ruby-full \
        autoconf \
        automake \
        pkg-config

# ==============================================================================
# Phase 3: Python Virtual Environment Setup
# ==============================================================================
# Create virtual environment IMMEDIATELY after Python installation
# This ensures all subsequent pip installs work correctly
ENV VIRTUAL_ENV=/opt/hexstrike/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3.12 -m venv "$VIRTUAL_ENV" && \
    . "$VIRTUAL_ENV/bin/activate" && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

# Speed up pip diagnostics (no version pinning)
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=120 \
    PIP_NO_PYTHON_VERSION_WARNING=1
# Ensure pipx CLIs on PATH
ENV PATH="/root/.local/bin:${PATH}"

# ==============================================================================
# Phase 4: Core Python Dependencies
# ==============================================================================
# Copy requirements.txt first for Docker layer caching optimization
COPY requirements.txt hexstrike_server.py hexstrike_mcp.py /opt/hexstrike/
# Install core Python dependencies into virtual environment
RUN pip install --no-cache-dir -r /opt/hexstrike/requirements.txt

# ==============================================================================
# Phase 5: Cloud & Container Security (Python CLIs)
# ==============================================================================
# Install cloud & container security CLIs (order matches pip/apt below)
# - ansible: Automation engine for configuration and orchestration
# - prowler: AWS/Azure/GCP security assessment with compliance checks (requires Python < 3.13)
# - ScoutSuite: Multi-cloud security auditing for AWS/Azure/GCP/Alibaba Cloud
# - Checkov: IaC security scanning for Terraform/CloudFormation/Kubernetes
# - kube-hunter: Kubernetes penetration testing (active/passive modes)
RUN apt-get install -y --no-install-recommends \
        ansible

# Install cloud/container Python CLIs in isolated environments via pipx (official for Python CLIs)
# - checkov: IaC scanning
# - prowler: Cloud compliance
# - ScoutSuite: Multi-cloud auditing
# - kube-hunter: Kubernetes security probing
# - shodan: Official Shodan CLI (Python)
# - censys: Official Censys CLI (Python)
RUN pipx install --pip-args="--no-cache-dir --prefer-binary" checkov     && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" prowler     && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" ScoutSuite  && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" kube-hunter && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" shodan      && \
    pipx install --pip-args="--no-cache-dir --prefer-binary" censys

# - Terrascan: Policy-as-code scanner for IaC
RUN curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && \
    tar -xf terrascan.tar.gz terrascan && rm terrascan.tar.gz && \
    install terrascan /usr/local/bin && rm terrascan

# - OpenTofu: Open-source Terraform-compatible CLI (official APT repository)
# - terraform (symlink): Compatibility symlink to tofu binary
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://get.opentofu.org/opentofu.gpg | tee /etc/apt/keyrings/opentofu.gpg >/dev/null && \
    curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg && \
    chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" > /etc/apt/sources.list.d/opentofu.list && \
    echo "deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" >> /etc/apt/sources.list.d/opentofu.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends tofu && \
    ln -sf /usr/bin/tofu /usr/local/bin/terraform

# - AWS CLI v2: Amazon Web Services Command Line Interface (official installer)
RUN cd /tmp && \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && \
    apt-get install -y --no-install-recommends unzip && \
    unzip -q awscliv2.zip && ./aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

# ==============================================================================
# Phase 6: Network & Reconnaissance Tools
# ==============================================================================
# Install network scanning and reconnaissance tools as documented in README.md
# Ensure core reconnaissance tools are present even on minimal Kali images
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
        samba-common-bin

# Install Rust-based network scanners
RUN cargo install rustscan

# ==============================================================================
# Phase 7: Web Application Security Tools
# ==============================================================================
# Install web application testing tools as documented in README.md
# Ensure required web tooling is installed explicitly for reproducibility
# - gobuster: Directory and DNS enumeration
# - feroxbuster: Recursive content discovery
# - ffuf: Fast web fuzzer
# - dotdotpwn: Path traversal fuzzer
# - xsser: XSS framework
# - wfuzz: Web application fuzzer
# - dirb: Web content scanner
# - dirsearch: Web path scanner
# - nikto: Web server vulnerability scanner
# - sqlmap: Automatic SQL injection tool
# - wpscan: WordPress security scanner
# - arjun: HTTP parameter discovery
# - paramspider: Parameter miner
# - hakrawler: Web endpoint crawler
# - wafw00f: WAF fingerprinting
# - whatweb: Web technology fingerprinting
# - burpsuite: Web security testing platform
# - zaproxy: OWASP ZAP web security scanner
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
# - clairctl: Container vulnerability assessment CLI
RUN go install -v github.com/projectdiscovery/katana/cmd/katana@latest && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest && \
    go install -v github.com/hahwul/dalfox/v2@latest && \
    go install -v github.com/jaeles-project/jaeles@latest && \
    go install -v github.com/lc/gau/v2/cmd/gau@latest && \
    go install -v github.com/tomnomnom/waybackurls@latest && \
    go install -v github.com/tomnomnom/assetfinder@latest && \
    go install -v github.com/tomnomnom/anew@latest && \
    go install -v github.com/tomnomnom/qsreplace@latest && \
    go install -v github.com/quay/clair/v4/cmd/clairctl@latest

# - kube-bench: CIS Kubernetes benchmark checker (installed from official GitHub release)
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) farch="linux_amd64" ;; \
      arm64) farch="linux_arm64" ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL https://api.github.com/repos/aquasecurity/kube-bench/releases/latest \
      | awk -v f="$farch" -F'"' '/browser_download_url/ && $0 ~ f".tar.gz" {print $4; exit}' \
      | xargs -r curl -fsSL -o /tmp/kube-bench.tgz; \
    tar -C /tmp -xzf /tmp/kube-bench.tgz kube-bench; \
    install /tmp/kube-bench /usr/local/bin/kube-bench; \
    rm -f /tmp/kube-bench.tgz /tmp/kube-bench

# Build x8 (hidden parameter discovery) from source using Cargo
RUN git clone --depth 1 https://github.com/Sh1Yo/x8.git /tmp/x8 && \
    cd /tmp/x8 && \
    cargo build --release && \
    install -m 0755 ./target/release/x8 /usr/local/bin/x8 && \
    rm -rf /tmp/x8

# ==============================================================================
# Phase 8: Authentication & Password Security Tools
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
        android-tools-adb

# Python-based binary helpers (latest stable releases)
# - ropgadget: ROP/JOP gadget finder
# - volatility3: Next-generation memory forensics framework
# - uro: URL declutterer / deduplication utility
RUN pip install --no-cache-dir \
        ropgadget \
        volatility3 \
        uro

# HashPump (CLI-compatible) via PyPI bindings:
# - hashpumpy: Python bindings providing length extension functionality
# - Provide a minimal wrapper that matches the original "hashpump" CLI interface
RUN pip install --no-cache-dir hashpumpy

# HashPump CLI wrapper (uses hashpumpy bindings from PyPI)
RUN cat >/usr/local/bin/hashpump <<'PY'
#!/usr/bin/env python3
import argparse
from hashpumpy import hashpump

parser = argparse.ArgumentParser(description="Hash length extension (HashPump-compatible wrapper)")
parser.add_argument("-s", "--signature", required=True, help="Original hex signature")
parser.add_argument("-d", "--data", required=True, help="Original data")
parser.add_argument("-k", "--key-length", required=True, type=int, help="Length of unknown key (bytes)")
parser.add_argument("-a", "--append-data", required=True, help="Data to append")
parser.add_argument("-m", "--algorithm", default="md5",
                    choices=["md5","sha1","sha256","sha512"],
                    help="Hash algorithm (default: md5)")
args, _ = parser.parse_known_args()

new_sig, new_msg = hashpump(args.signature, args.data, args.append_data, args.key_length, args.algorithm)
if isinstance(new_msg, bytes):
    try:
        new_msg = new_msg.decode("latin1")
    except Exception:
        new_msg = new_msg.decode("utf-8", errors="ignore")

print(f"New signature: {new_sig}")
print(f"New string: {new_msg}")
PY

RUN chmod +x /usr/local/bin/hashpump

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
# Phase 11: Wireless & Packet Analysis Tools
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
# - metasploit-framework: Penetration testing framework
RUN apt-get install -y --no-install-recommends \
        metasploit-framework

# ==============================================================================
# Phase 13: Runtime Security Agents
# ==============================================================================
# - falco: Runtime security tool (official APT repository, noninteractive)
#   NOTE: during image build we avoid post-install scripts (systemd/dkms/driver)
#   by downloading the .deb and extracting files without running maintainer scripts.
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

# Additional CLI utilities required by MCP endpoints
# - newman: Postman CLI
# - insomnia-inso: Insomnia CLI
RUN npm install -g \
        newman \
        insomnia-inso

# ==============================================================================
# Phase 14: Browser Agent Requirements
# ==============================================================================
# Install Chrome/Chromium and ChromeDriver as documented in README.md
# Required for Browser Agent functionality with Selenium
# - chromium: Chromium browser
# - chromium-driver: WebDriver for Chromium
RUN apt-get install -y --no-install-recommends \
        chromium \
        chromium-driver

# ==============================================================================
# Phase 15: Security Tool Repositories & Wrappers
# ==============================================================================
RUN mkdir -p /opt/hexstrike/tools && \
    git clone --depth 1 https://github.com/duo-labs/cloudmapper.git /opt/hexstrike/tools/cloudmapper && \
    rm -rf /opt/hexstrike/tools/cloudmapper/.git && \
    git clone --depth 1 https://github.com/RhinoSecurityLabs/pacu.git /opt/hexstrike/tools/pacu && \
    rm -rf /opt/hexstrike/tools/pacu/.git && \
    git clone --depth 1 https://github.com/ticarpi/jwt_tool.git /opt/hexstrike/tools/jwt_tool && \
    rm -rf /opt/hexstrike/tools/jwt_tool/.git && \
    git clone --depth 1 https://github.com/niklasb/libc-database.git /opt/hexstrike/tools/libc-database && \
    rm -rf /opt/hexstrike/tools/libc-database/.git && \
    git clone --depth 1 https://github.com/longld/peda.git /root/peda && \
    rm -rf /root/peda/.git && \
    mkdir -p /opt/stegsolve && \
    curl -fsSL -o /opt/stegsolve/stegsolve.jar https://github.com/zardus/ctf-tools/raw/master/stegsolve/Stegsolve.jar && \
    chmod 644 /opt/stegsolve/stegsolve.jar && \
    ln -s /opt/hexstrike/tools/libc-database /opt/libc-database && \
    ln -s /opt/hexstrike/tools/jwt_tool /opt/jwt_tool

# Install Python dependencies for cloned tools inside virtual environment
RUN pip install --no-cache-dir -r /opt/hexstrike/tools/cloudmapper/requirements.txt && \
    pip install --no-cache-dir -r /opt/hexstrike/tools/pacu/requirements.txt && \
    pip install --no-cache-dir -r /opt/hexstrike/tools/jwt_tool/requirements.txt

# Create convenience entrypoints expected by MCP routes/health checks
RUN printf '#!/bin/bash\npython3 /opt/hexstrike/tools/cloudmapper/cloudmapper.py "$@"\n' > /usr/local/bin/cloudmapper && \
    chmod +x /usr/local/bin/cloudmapper && \
    printf '#!/bin/bash\npython3 /opt/hexstrike/tools/pacu/pacu.py "$@"\n' > /usr/local/bin/pacu && \
    chmod +x /usr/local/bin/pacu && \
    mkdir -p /opt/burpsuite && \
    if [ -f /usr/share/burpsuite/burpsuite.jar ]; then ln -sf /usr/share/burpsuite/burpsuite.jar /opt/burpsuite/burpsuite.jar; fi && \
    ln -sf /usr/local/bin/newman /usr/local/bin/postman && \
    ln -sf /usr/local/bin/inso /usr/local/bin/insomnia && \
    ln -sf /usr/local/bin/vol /usr/local/bin/volatility && \
    printf '#!/bin/bash\nnpx --yes graphql-playground-html "$@"\n' > /usr/local/bin/graphql-playground && \
    chmod +x /usr/local/bin/graphql-playground && \
    printf '#!/bin/bash\nnpx --yes graphql-voyager "$@"\n' > /usr/local/bin/graphql-voyager && \
    chmod +x /usr/local/bin/graphql-voyager && \
    printf '#!/usr/bin/env python3\nimport json,sys\n\nif len(sys.argv) < 2:\n    print("Usage: api-schema-analyzer <schema-file>")\n    sys.exit(1)\npath = sys.argv[1]\nwith open(path, "r", encoding="utf-8") as f:\n    data = json.load(f)\npaths = data.get("paths", {})\nprint(f"Endpoints: {len(paths)}")\nfor route, methods in paths.items():\n    verbs = ', '.join(m.upper() for m in methods.keys())\n    print(f"- {route}: {verbs}")\n' > /usr/local/bin/api-schema-analyzer && \
    chmod +x /usr/local/bin/api-schema-analyzer

# ==============================================================================
# Phase 16: Image Cleanup
# ==============================================================================
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 17: Cloud & Container Security Binaries
# ==============================================================================
# Install Trivy (container vulnerability scanner)
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
    sh -s -- -b /usr/local/bin

# Install docker-bench-security (Docker daemon configuration audit)
RUN mkdir -p /opt/hexstrike/tools && \
    git clone --depth 1 https://github.com/docker/docker-bench-security.git /opt/hexstrike/tools/docker-bench-security && \
    rm -rf /opt/hexstrike/tools/docker-bench-security/.git && \
    printf '#!/bin/bash\nset -e\ncd /opt/hexstrike/tools/docker-bench-security\nexec ./docker-bench-security.sh "$@"\n' > /usr/local/bin/docker-bench-security && \
    chmod +x /usr/local/bin/docker-bench-security

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
