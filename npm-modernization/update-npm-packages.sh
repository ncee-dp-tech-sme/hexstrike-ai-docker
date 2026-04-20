#!/bin/bash
################################################################################
# NPM Package Modernization Script for HexStrike AI Container
################################################################################
# This script updates deprecated NPM packages inside a running container
# according to the modernization strategy documented in PACKAGE_REPLACEMENT_MAPPING.md
#
# Usage:
#   1. Copy this script into a running container:
#      docker cp npm-modernization/update-npm-packages.sh <container-name>:/tmp/
#   2. Execute inside the container:
#      docker exec -it <container-name> bash /tmp/update-npm-packages.sh
#   3. Or run directly:
#      docker exec -it <container-name> bash < npm-modernization/update-npm-packages.sh
#
# Author: Bob (AI Assistant)
# Date: 2026-02-22
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/tmp/npm-modernization-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        log_success "$1 is available"
        return 0
    else
        log_error "$1 is not available"
        return 1
    fi
}

################################################################################
# Pre-flight Checks
################################################################################

log "Starting NPM Package Modernization"
log "Log file: $LOG_FILE"
echo ""

log "Running pre-flight checks..."

# Check if running as root (recommended for global npm packages)
if [ "$EUID" -ne 0 ]; then 
    log_warning "Not running as root. Some operations may fail."
    log_warning "Consider running with: docker exec -it --user root <container> bash /tmp/update-npm-packages.sh"
fi

# Check required commands
check_command npm || { log_error "npm not found. Exiting."; exit 1; }
check_command node || { log_error "node not found. Exiting."; exit 1; }

# Display current versions
log "Current Node.js version: $(node --version)"
log "Current NPM version: $(npm --version)"
echo ""

################################################################################
# Backup Current State
################################################################################

log "Creating backup of current NPM packages..."
npm list -g --depth=0 > /tmp/npm-packages-before-update.txt 2>&1 || true
log_success "Backup saved to /tmp/npm-packages-before-update.txt"
echo ""

################################################################################
# Phase 1: Security Updates (High Priority)
################################################################################

log "=========================================="
log "Phase 1: Security Updates"
log "=========================================="
echo ""

# Update UUID (CVE fix)
log "Updating uuid (CVE - Math.random() vulnerability)..."
if npm list -g uuid &> /dev/null; then
    npm install -g uuid@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "uuid updated to $(npm list -g uuid --depth=0 2>/dev/null | grep uuid@ || echo 'latest')"
else
    log_warning "uuid not found as global package (may be a dependency)"
fi
echo ""

# Update Glob (Multiple CVEs)
log "Updating glob (Multiple CVEs)..."
if npm list -g glob &> /dev/null; then
    npm install -g glob@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "glob updated"
else
    log_warning "glob not found as global package (may be a dependency)"
fi
echo ""

# Update XMLDom (CVE-2021-21366)
log "Updating xmldom to @xmldom/xmldom (CVE-2021-21366)..."
if npm list -g xmldom &> /dev/null; then
    npm uninstall -g xmldom 2>&1 | tee -a "$LOG_FILE"
    npm install -g @xmldom/xmldom@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "@xmldom/xmldom installed"
else
    log_warning "xmldom not found as global package (may be a dependency)"
fi
echo ""

# Update Tar (Multiple CVEs)
log "Updating tar (Multiple CVEs)..."
if npm list -g tar &> /dev/null; then
    npm install -g tar@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "tar updated"
else
    log_warning "tar not found as global package (may be a dependency)"
fi
echo ""

################################################################################
# Phase 2: GraphQL Tools Update (High Priority)
################################################################################

log "=========================================="
log "Phase 2: GraphQL Tools Update"
log "=========================================="
echo ""

# Update GraphQL Inspector
log "Updating graphql-inspector to @graphql-inspector/cli..."
if npm list -g graphql-inspector &> /dev/null; then
    npm uninstall -g graphql-inspector 2>&1 | tee -a "$LOG_FILE"
    npm install -g @graphql-inspector/cli@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "@graphql-inspector/cli installed"
    
    # Update symlink for graphql-scanner alias
    if [ -L /usr/local/bin/graphql-scanner ]; then
        log "Updating graphql-scanner symlink..."
        rm -f /usr/local/bin/graphql-scanner
        ln -sf /usr/local/bin/graphql-inspector /usr/local/bin/graphql-scanner
        log_success "graphql-scanner symlink updated"
    fi
else
    log_warning "graphql-inspector not found as global package"
fi
echo ""

# Update GraphQL Core
log "Updating graphql to v16..."
if npm list -g graphql &> /dev/null; then
    npm install -g graphql@16 2>&1 | tee -a "$LOG_FILE"
    log_success "graphql updated to v16"
else
    log_warning "graphql not found as global package (may be a dependency)"
fi
echo ""

# Update GraphQL Tools (if installed)
log "Checking for graphql-tools..."
if npm list -g graphql-tools &> /dev/null; then
    log "Replacing graphql-tools with scoped packages..."
    npm uninstall -g graphql-tools 2>&1 | tee -a "$LOG_FILE"
    npm install -g @graphql-tools/schema@latest @graphql-tools/utils@latest @graphql-tools/merge@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "graphql-tools replaced with scoped packages"
else
    log_warning "graphql-tools not found as global package"
fi
echo ""

################################################################################
# Phase 3: Utility Library Updates (Medium Priority)
################################################################################

log "=========================================="
log "Phase 3: Utility Library Updates"
log "=========================================="
echo ""

# Update Core-js
log "Updating core-js to v3..."
if npm list -g core-js &> /dev/null; then
    npm install -g core-js@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "core-js updated to v3"
else
    log_warning "core-js not found as global package (may be a dependency)"
fi
echo ""

# Update Faker
log "Updating @faker-js/faker..."
if npm list -g @faker-js/faker &> /dev/null; then
    npm install -g @faker-js/faker@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "@faker-js/faker updated"
else
    log_warning "@faker-js/faker not found as global package"
fi
echo ""

# Update Rimraf
log "Updating rimraf to v6..."
if npm list -g rimraf &> /dev/null; then
    npm install -g rimraf@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "rimraf updated"
else
    log_warning "rimraf not found as global package"
fi
echo ""

# Update JSON Schema Parser
log "Updating json-schema-ref-parser to @apidevtools/json-schema-ref-parser..."
if npm list -g json-schema-ref-parser &> /dev/null; then
    npm uninstall -g json-schema-ref-parser 2>&1 | tee -a "$LOG_FILE"
    npm install -g @apidevtools/json-schema-ref-parser@latest 2>&1 | tee -a "$LOG_FILE"
    log_success "@apidevtools/json-schema-ref-parser installed"
else
    log_warning "json-schema-ref-parser not found as global package"
fi
echo ""

################################################################################
# Phase 4: Optional Updates (Low Priority)
################################################################################

log "=========================================="
log "Phase 4: Optional Updates"
log "=========================================="
echo ""

# Note about Insomnia CLI
log_warning "Insomnia CLI (insomnia-inso) is deprecated but KEPT by design"
log_warning "It is required by hexstrike_server.py and has no suitable replacement"
log_warning "Monitoring for alternatives is recommended"
echo ""

# Check for Apollo Server packages (informational only)
log "Checking for Apollo Server packages (informational)..."
if npm list -g apollo-server &> /dev/null || npm list -g apollo-server-express &> /dev/null; then
    log_warning "Apollo Server v2 packages detected (EOL October 2024)"
    log_warning "Manual migration to @apollo/server v4 required if used"
    log_warning "See PACKAGE_REPLACEMENT_MAPPING.md for migration guide"
else
    log "No Apollo Server packages found as global installs"
fi
echo ""

################################################################################
# Phase 5: Cleanup and Verification
################################################################################

log "=========================================="
log "Phase 5: Cleanup and Verification"
log "=========================================="
echo ""

# Clear npm cache
log "Clearing npm cache..."
npm cache clean --force 2>&1 | tee -a "$LOG_FILE"
log_success "npm cache cleared"
echo ""

# Save updated package list
log "Saving updated package list..."
npm list -g --depth=0 > /tmp/npm-packages-after-update.txt 2>&1 || true
log_success "Updated package list saved to /tmp/npm-packages-after-update.txt"
echo ""

# Check for remaining deprecation warnings
log "Checking for remaining deprecation warnings..."
npm list -g --depth=0 2>&1 | grep -i "deprecated" > /tmp/npm-remaining-warnings.txt || true
if [ -s /tmp/npm-remaining-warnings.txt ]; then
    log_warning "Some deprecation warnings remain (see /tmp/npm-remaining-warnings.txt)"
    log_warning "Most are likely transitive dependencies and will update automatically"
else
    log_success "No deprecation warnings found!"
fi
echo ""

################################################################################
# Summary Report
################################################################################

log "=========================================="
log "Update Summary"
log "=========================================="
echo ""

log "Packages before update: /tmp/npm-packages-before-update.txt"
log "Packages after update: /tmp/npm-packages-after-update.txt"
log "Remaining warnings: /tmp/npm-remaining-warnings.txt"
log "Full log: $LOG_FILE"
echo ""

# Compare package counts
BEFORE_COUNT=$(grep -c "^" /tmp/npm-packages-before-update.txt 2>/dev/null || echo "0")
AFTER_COUNT=$(grep -c "^" /tmp/npm-packages-after-update.txt 2>/dev/null || echo "0")

log "Global packages before: $BEFORE_COUNT"
log "Global packages after: $AFTER_COUNT"
echo ""

################################################################################
# Verification Tests
################################################################################

log "=========================================="
log "Running Verification Tests"
log "=========================================="
echo ""

# Test critical tools
log "Testing critical tools..."

test_tool() {
    local tool=$1
    if command -v "$tool" &> /dev/null; then
        log_success "$tool is available"
        return 0
    else
        log_error "$tool is NOT available"
        return 1
    fi
}

test_tool "graphql-inspector" || log_warning "graphql-inspector not found (check @graphql-inspector/cli)"
test_tool "graphql-scanner" || log_warning "graphql-scanner alias not found"
test_tool "newman"
test_tool "insomnia"
test_tool "jwt-cracker"
test_tool "social-analyzer"

echo ""

################################################################################
# Recommendations
################################################################################

log "=========================================="
log "Recommendations"
log "=========================================="
echo ""

log "1. Review /tmp/npm-remaining-warnings.txt for any critical warnings"
log "2. Test the hexstrike-ai MCP server functionality"
log "3. Verify all API tools are working: curl http://localhost:8888/health"
log "4. If everything works, update the Dockerfile with these changes"
log "5. Monitor Insomnia CLI for alternatives or plan custom solution"
echo ""

log_success "NPM Package Modernization Complete!"
log "Total execution time: $SECONDS seconds"
echo ""

exit 0

# Made with Bob
