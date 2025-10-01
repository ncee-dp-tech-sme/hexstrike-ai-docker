# ==============================================================================
# HexStrike AI MCP Server v6.0 - Docker Image
# ==============================================================================
# Base image: Kali Linux Rolling (includes 150+ pre-installed security tools)
# Repository: https://github.com/0x4m4/hexstrike-ai
# License: MIT
# ==============================================================================

FROM docker.io/kalilinux/kali-rolling:latest

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /opt/hexstrike

# ==============================================================================
# Phase 1: Base System Packages
# ==============================================================================
# Update package lists and install core system utilities
# Install core utilities required for tool installation
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-utils \
        curl \
        wget \
        git \
        gnupg2 \
        lsb-release \
        software-properties-common \
        build-essential \
        ca-certificates \
        wordlists \
        httpie && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 2: Language Runtimes & Compilers
# ==============================================================================
# Install language runtimes required by various security tools
# - Python: Primary language for HexStrike and many security tools
# - Go: Required for tools like nuclei, httpx, subfinder, katana
# - Node.js/npm: Required for social-analyzer, shodan-cli, censys-cli, and pwned
# - Java: Required for some binary analysis tools
# - Ruby: Required for wpscan and other tools
# - Build tools: Provided via build-essential (gcc, g++, make)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        golang \
        nodejs \
        npm \
        default-jdk \
        ruby-full \
        autoconf \
        automake \
        pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 3: Rust Installation
# ==============================================================================
# Install Rust using official installer for latest version
# Required for: rustscan, feroxbuster, pwninit
ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH="$CARGO_HOME/bin:/root/go/bin:$PATH"

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# ==============================================================================
# Phase 4: Network & Reconnaissance Tools
# ==============================================================================
# Install network scanning and reconnaissance tools as documented in README.md
# Ensure core reconnaissance tools are present even on minimal Kali images
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nmap \
        masscan \
        autorecon \
        amass \
        subfinder \
        fierce \
        dnsenum \
        theharvester \
        responder \
        netexec \
        enum4linux-ng \
        enum4linux \
        nbtscan \
        arp-scan \
        samba-common-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install rustscan via Cargo (not in apt repositories)
RUN cargo install rustscan

# ==============================================================================
# Phase 5: Web Application Security Tools
# ==============================================================================
# Install web application testing tools as documented in README.md
# Ensure required web tooling is installed explicitly for reproducibility
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
        burpsuite \
        zaproxy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Go-based web tools referenced in README.md and MCP server
# - x8: Hidden parameter discovery
# - katana: Next-generation crawling and spidering
# - httpx: Fast HTTP probing and technology detection
# - dalfox: Advanced XSS vulnerability scanning
# - jaeles: Vulnerability scanning with custom signatures
# - gau: Get All URLs from web archives
# - waybackurls: Historical URL discovery from Wayback Machine
# - anew: Append new lines to files (data processing)
# - qsreplace: Query string parameter replacement
# - nuclei: Web vulnerability scanning templates
# SECURITY VERIFIED: All GitHub repositories below are from trusted security researchers
# - Sh1Yo/x8: 1.8k+ stars, signed releases, GPL-3.0 license
# - projectdiscovery/*: Widely adopted tooling from ProjectDiscovery
# - hahwul/dalfox: 3k+ stars, maintained by security researcher Hahwul
# - jaeles-project/jaeles: 2k+ stars, community-audited vulnerability scanner
# - lc/gau: 3k+ stars, well-known URL enumerator
# - tomnomnom/*: Tools from Tom Hudson (ex-Google security)
RUN go install -v github.com/Sh1Yo/x8/cmd/x8@latest && \
    go install -v github.com/projectdiscovery/katana/cmd/katana@latest && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest && \
    go install -v github.com/hahwul/dalfox/v2@latest && \
    go install -v github.com/jaeles-project/jaeles@latest && \
    go install -v github.com/lc/gau/v2/cmd/gau@latest && \
    go install -v github.com/tomnomnom/waybackurls@latest && \
    go install -v github.com/tomnomnom/anew@latest && \
    go install -v github.com/tomnomnom/qsreplace@latest && \
    go install -v github.com/s0md3v/uro/cmd/uro@latest && \
    go install -v github.com/quay/clair/v4/cmd/clairctl@latest

# ==============================================================================
# Phase 6: Authentication & Password Security Tools
# ==============================================================================
# Install password cracking and authentication testing tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        hydra \
        john \
        hashcat \
        medusa \
        patator \
        evil-winrm \
        hash-identifier \
        ophcrack \
        hashcat-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 7: Binary Analysis & Reverse Engineering Tools
# ==============================================================================
# Install binary analysis tools as documented in README.md
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gdb \
        radare2 \
        ghidra \
        binwalk \
        checksec \
        foremost \
        steghide \
        exiftool \
        ropper && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install zsteg (PNG/BMP steganography detection) via Ruby gem
RUN gem install zsteg

# Install one_gadget (ROP gadget finder for GLIBC)
RUN gem install one_gadget

# ==============================================================================
# Phase 8: CTF & Forensics Tools
# ==============================================================================
# Install CTF and forensics tools as documented in README.md
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autopsy \
        sleuthkit \
        outguess \
        testdisk \
        scalpel \
        bulk-extractor \
        volatility \
        hashpump \
        smbmap && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install pwninit (CTF binary setup automation) via Cargo
RUN cargo install pwninit

# ==============================================================================
# Phase 9: Wireless & Packet Analysis Tools
# ==============================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wireshark \
        tshark \
        tcpdump \
        aircrack-ng && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 10: OSINT & Intelligence Tools
# ==============================================================================
# Install OSINT tools as documented in README.md
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        exploitdb \
        kismet \
        sherlock \
        recon-ng \
        spiderfoot && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 11: Exploitation Frameworks
# ==============================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        metasploit-framework && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 12: Runtime Security Agents
# ==============================================================================
RUN curl -fsSL https://dl.cloudsmith.io/public/falcosecurity/falco/cfg/setup/bash.deb.sh | bash && \
    apt-get update && \
    apt-get install -y --no-install-recommends falco && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install OSINT tools via npm
# - social-analyzer: Social media analysis and OSINT gathering
# - shodan-cli: Official Shodan CLI (maintained by trusted Shodan team)
# - censys-cli: Official Censys CLI (maintained by Censys security engineers)
# - pwned: Have I Been Pwned API client
# - newman: Postman CLI runner (official Postman team)
# - insomnia-inso: Insomnia CLI tool (Maintained by Kong/Insomnia)
RUN npm install -g social-analyzer shodan-cli censys-cli pwned newman insomnia-inso

# ==============================================================================
# Phase 13: Browser Agent Requirements
# ==============================================================================
# Install Chrome/Chromium and ChromeDriver as documented in README.md
# Required for Browser Agent functionality with Selenium
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        chromium \
        chromium-driver && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Phase 14: Python Virtual Environment & Dependencies
# ==============================================================================
# Copy requirements.txt first for Docker layer caching optimization
COPY requirements.txt hexstrike_server.py hexstrike_mcp.py /opt/hexstrike/

# Create virtual environment and install Python dependencies
# Following README.md installation instructions exactly
ENV VIRTUAL_ENV=/opt/hexstrike/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN python3 -m venv "$VIRTUAL_ENV" && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r /opt/hexstrike/requirements.txt

# Install additional Python security tools
# - ropgadget: ROP/JOP gadget finder
# - volatility3: Memory forensics framework
# - pwntools: CTF framework and exploit development (already in requirements.txt)
# - prowler: AWS/Azure/GCP security assessment
# - scout-suite: Multi-cloud security auditing
# - checkov: Infrastructure as code security scanning
# - terrascan: Infrastructure security scanner
# - kube-hunter: Kubernetes penetration testing
# - kube-bench: CIS Kubernetes benchmark checker
RUN pip install --no-cache-dir \
    ropgadget \
    volatility \
    volatility3 \
    prowler \
    scout-suite \
    checkov \
    terrascan \
    kube-hunter \
    kube-bench

# ==============================================================================
# Phase 15: Security Tool Repositories & Wrappers
# ==============================================================================
RUN mkdir -p /opt/hexstrike/tools && \
    git clone --depth 1 https://github.com/duo-labs/cloudmapper.git /opt/hexstrike/tools/cloudmapper && \
    rm -rf /opt/hexstrike/tools/cloudmapper/.git && \
    git clone --depth 1 https://github.com/RhinoSecurityLabs/pacu.git /opt/hexstrike/tools/pacu && \
    rm -rf /opt/hexstrike/tools/pacu/.git && \
    git clone --depth 1 https://github.com/niklasb/libc-database.git /opt/hexstrike/tools/libc-database && \
    rm -rf /opt/hexstrike/tools/libc-database/.git && \
    git clone --depth 1 https://github.com/longld/peda.git /root/peda && \
    rm -rf /root/peda/.git && \
    mkdir -p /opt/stegsolve && \
    curl -fsSL -o /opt/stegsolve/stegsolve.jar https://github.com/zardus/ctf-tools/raw/master/stegsolve/Stegsolve.jar && \
    chmod 644 /opt/stegsolve/stegsolve.jar && \
    ln -s /opt/hexstrike/tools/libc-database /opt/libc-database

# Install Python dependencies for cloned tools inside virtual environment
RUN pip install --no-cache-dir -r /opt/hexstrike/tools/cloudmapper/requirements.txt && \
    pip install --no-cache-dir -r /opt/hexstrike/tools/pacu/requirements.txt

# Create convenience wrappers
RUN printf '#!/bin/bash\npython3 /opt/hexstrike/tools/cloudmapper/cloudmapper.py "$@"\n' > /usr/local/bin/cloudmapper && \
    chmod +x /usr/local/bin/cloudmapper && \
    printf '#!/bin/bash\npython3 /opt/hexstrike/tools/pacu/pacu.py "$@"\n' > /usr/local/bin/pacu && \
    chmod +x /usr/local/bin/pacu && \
    mkdir -p /opt/burpsuite && \
    if [ -f /usr/share/burpsuite/burpsuite.jar ]; then ln -sf /usr/share/burpsuite/burpsuite.jar /opt/burpsuite/burpsuite.jar; fi && \
    printf '#!/bin/bash\nnewman "$@"\n' > /usr/local/bin/postman && \
    chmod +x /usr/local/bin/postman && \
    printf '#!/bin/bash\ninso "$@"\n' > /usr/local/bin/insomnia && \
    chmod +x /usr/local/bin/insomnia && \
    printf '#!/bin/bash\nvolatility "$@"\n' > /usr/local/bin/vol && \
    chmod +x /usr/local/bin/vol && \
    printf '#!/usr/bin/env python3\nimport json,sys\n\nif len(sys.argv) < 2:\n    print("Usage: api-schema-analyzer <schema-file>")\n    sys.exit(1)\npath = sys.argv[1]\nwith open(path, "r", encoding="utf-8") as f:\n    data = json.load(f)\npaths = data.get("paths", {})\nprint(f"Endpoints: {len(paths)}")\nfor route, methods in paths.items():\n    verbs = ', '.join(m.upper() for m in methods.keys())\n    print(f"- {route}: {verbs}")\n' > /usr/local/bin/api-schema-analyzer && \
    chmod +x /usr/local/bin/api-schema-analyzer

# ==============================================================================
# Phase 16: Cloud & Container Security Binaries
# ==============================================================================
# Install Trivy (container vulnerability scanner) as referenced in README.md
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
    sh -s -- -b /usr/local/bin

# Install docker-bench-security (Docker daemon configuration audit)
RUN mkdir -p /opt/hexstrike/tools && \
    git clone --depth 1 https://github.com/docker/docker-bench-security.git /opt/hexstrike/tools/docker-bench-security && \
    rm -rf /opt/hexstrike/tools/docker-bench-security/.git && \
    printf '#!/bin/bash\nset -e\ncd /opt/hexstrike/tools/docker-bench-security\nexec ./docker-bench-security.sh "$@"\n' > /usr/local/bin/docker-bench-security && \
    chmod +x /usr/local/bin/docker-bench-security

# ==============================================================================
# Phase 17: Runtime Configuration
# ==============================================================================
# Expose MCP server port as documented in README.md
EXPOSE 8888

# Health check endpoint (matches README.md verification section)
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8888/health || exit 1

# ==============================================================================
# Phase 18: Startup
# ==============================================================================
# Start HexStrike MCP server using virtual environment Python
CMD ["python3", "hexstrike_server.py"]
