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
# PHASE 1: System Update & Base Dependencies
# ==============================================================================
# Update package lists and upgrade system
# Install core utilities required for tool installation
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        apt-utils \
        curl \
        wget \
        git \
        gnupg2 \
        lsb-release \
        software-properties-common \
        build-essential \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# PHASE 2: Language Runtimes & Compilers
# ==============================================================================
# Install language runtimes required by various security tools
# - Python: Primary language for HexStrike and many security tools
# - Go: Required for tools like nuclei, httpx, subfinder, katana
# - Node.js/npm: Required for social-analyzer, shodan-cli, censys-cli
# - Java: Required for some binary analysis tools
# - Ruby: Required for wpscan and other tools
# - GCC/Make: Required for compiling tools from source
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
        gcc \
        g++ \
        make \
        autoconf \
        automake \
        pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# PHASE 3: Rust Installation
# ==============================================================================
# Install Rust using official installer for latest version
# Required for: rustscan, feroxbuster, pwninit
ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH="$CARGO_HOME/bin:$PATH"

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    . "$CARGO_HOME/env"

# ==============================================================================
# PHASE 4: Network & Reconnaissance Tools
# ==============================================================================
# Install network scanning and reconnaissance tools as documented in README.md
# Note: nmap, masscan, amass, theharvester are already in Kali default
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autorecon \
        subfinder \
        fierce \
        dnsenum \
        responder \
        netexec \
        enum4linux-ng \
        arp-scan && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install rustscan via Cargo (not in apt repositories)
RUN cargo install rustscan

# ==============================================================================
# PHASE 5: Web Application Security Tools
# ==============================================================================
# Install web application testing tools as documented in README.md
# Note: gobuster, nikto, sqlmap, dirb, wafw00f are already in Kali default
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        feroxbuster \
        ffuf \
        dirsearch \
        wpscan \
        arjun \
        paramspider \
        hakrawler && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install nuclei (latest version via Go)
RUN go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

# Install additional Go-based web tools referenced in README.md
# - x8: Hidden parameter discovery
# - katana: Next-generation crawling and spidering
# - httpx: Fast HTTP probing and technology detection
# - dalfox: Advanced XSS vulnerability scanning
# - jaeles: Vulnerability scanning with custom signatures
# - gau: Get All URLs from web archives
# - waybackurls: Historical URL discovery from Wayback Machine
# - anew: Append new lines to files (data processing)
# - qsreplace: Query string parameter replacement
RUN go install -v github.com/ffffffff0x/x8@latest && \
    go install -v github.com/projectdiscovery/katana/cmd/katana@latest && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install -v github.com/hahwul/dalfox/v2@latest && \
    go install -v github.com/jaeles-project/jaeles@latest && \
    go install -v github.com/lc/gau/v2/cmd/gau@latest && \
    go install -v github.com/tomnomnom/waybackurls@latest && \
    go install -v github.com/tomnomnom/anew@latest && \
    go install -v github.com/tomnomnom/qsreplace@latest

# ==============================================================================
# PHASE 6: Authentication & Password Security Tools
# ==============================================================================
# Install password cracking and authentication testing tools
# Note: hydra, john, hashcat are already in Kali default
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        medusa \
        patator \
        evil-winrm \
        hash-identifier \
        ophcrack && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# PHASE 7: Binary Analysis & Reverse Engineering Tools
# ==============================================================================
# Install binary analysis tools as documented in README.md
# Note: gdb, radare2, ghidra, binwalk, checksec are already in Kali default
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        foremost \
        steghide \
        exiftool \
        ropper && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install zsteg (PNG/BMP steganography detection) via Ruby gem
RUN gem install zsteg

# ==============================================================================
# PHASE 8: CTF & Forensics Tools
# ==============================================================================
# Install CTF and forensics tools as documented in README.md
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autopsy \
        sleuthkit \
        outguess \
        testdisk \
        scalpel \
        bulk-extractor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install pwninit (CTF binary setup automation) via Cargo
RUN cargo install pwninit

# ==============================================================================
# PHASE 9: OSINT & Intelligence Tools
# ==============================================================================
# Install OSINT tools as documented in README.md
# Note: sherlock, recon-ng, maltego, spiderfoot are already in Kali default
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        exploitdb \
        kismet && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install OSINT tools via npm
# - social-analyzer: Social media analysis and OSINT gathering
# - shodan-cli: Shodan search engine CLI
# - censys-cli: Censys search engine CLI
# - pwned: Have I Been Pwned API client
RUN npm install -g social-analyzer shodan-cli censys-cli pwned

# ==============================================================================
# PHASE 10: Browser Agent Requirements
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
# PHASE 11: Python Virtual Environment & Dependencies
# ==============================================================================
# Copy requirements.txt first for Docker layer caching optimization
COPY requirements.txt /opt/hexstrike/requirements.txt

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
    volatility3 \
    prowler \
    scout-suite \
    checkov \
    terrascan \
    kube-hunter \
    kube-bench

# ==============================================================================
# PHASE 12: Application Files
# ==============================================================================
# Copy application source code
COPY hexstrike_server.py /opt/hexstrike/
COPY hexstrike_mcp.py /opt/hexstrike/

# Ensure Go binaries are in PATH
ENV PATH="$PATH:/root/go/bin"

# ==============================================================================
# PHASE 13: Runtime Configuration
# ==============================================================================
# Expose MCP server port as documented in README.md
EXPOSE 8888

# Health check endpoint (matches README.md verification section)
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8888/health || exit 1

# ==============================================================================
# PHASE 14: Startup
# ==============================================================================
# Start HexStrike MCP server using virtual environment Python
# Follows README.md: python3 hexstrike_server.py
CMD ["python3", "hexstrike_server.py"]
