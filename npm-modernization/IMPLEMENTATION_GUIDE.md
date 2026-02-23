# NPM Modernization Implementation Guide

## Overview
This guide provides step-by-step instructions for implementing the NPM package modernization in the HexStrike AI Docker image.

---

## Prerequisites

- Docker installed and running
- Git repository access
- Backup of current working Dockerfile
- Estimated time: 10-15 hours
- Testing environment available

---

## Phase 1: Preparation (30 minutes)

### Step 1.1: Create Backup
```bash
# Backup current files
cp docker/Dockerfile npm-modernization/Dockerfile.backup
cp docker/docker-compose.yml npm-modernization/docker-compose.yml.backup
cp requirements.txt npm-modernization/requirements.txt.backup

# Create working copy
cp docker/Dockerfile npm-modernization/Dockerfile.new
```

### Step 1.2: Document Current State
```bash
# Build current image and document size
docker build -t hexstrike-ai:before -f docker/Dockerfile .
docker images hexstrike-ai:before > npm-modernization/image-size-before.txt

# Test current functionality
docker run --rm hexstrike-ai:before /usr/local/bin/insomnia --version
docker run --rm hexstrike-ai:before node --version
docker run --rm hexstrike-ai:before npm list -g --depth=0 > npm-modernization/npm-packages-before.txt
```

---

## Phase 2: Security Updates (2 hours)

### Step 2.1: Update UUID
**File**: `npm-modernization/Dockerfile.new`
**Line**: Search for any uuid installation

**Change**:
```dockerfile
# If uuid is explicitly installed, update version
# Otherwise, it will be updated as a dependency
```

**Test**:
```bash
docker build -t hexstrike-ai:uuid-test -f npm-modernization/Dockerfile.new .
docker run --rm hexstrike-ai:uuid-test node -e "console.log(require('uuid').version)"
```

### Step 2.2: Update Glob, Tar, and XMLDom
These are typically dependencies, not directly installed. They'll be updated when parent packages are updated.

**Verification**:
```bash
docker run --rm hexstrike-ai:test npm list -g glob tar
```

---

## Phase 3: GraphQL Tools Update (2 hours)

### Step 3.1: Update GraphQL Inspector

**File**: `npm-modernization/Dockerfile.new`
**Line**: ~557 (in the npm install -g section)

**Current**:
```dockerfile
RUN npm install -g \
        social-analyzer \
        pwned \
        graphql-inspector \
        jwt-cracker \
        graphql-playground-html \
        graphql-voyager \
        newman
```

**New**:
```dockerfile
RUN npm install -g \
        social-analyzer \
        pwned \
        @graphql-inspector/cli@latest \
        jwt-cracker \
        graphql-playground-html \
        graphql-voyager \
        newman
```

### Step 3.2: Update GraphQL Core

**Add after the npm install section**:
```dockerfile
# Update GraphQL to v16 for better compatibility
RUN npm install -g graphql@16
```

### Step 3.3: Update Wrapper Script

**File**: `npm-modernization/Dockerfile.new`
**Line**: ~790 (graphql-scanner alias)

**Current**:
```dockerfile
ln -sf /usr/local/bin/graphql-inspector        /usr/local/bin/graphql-scanner && \
```

**New**:
```dockerfile
ln -sf /usr/local/bin/graphql-inspector-cli    /usr/local/bin/graphql-scanner && \
```

**Test**:
```bash
docker build -t hexstrike-ai:graphql-test -f npm-modernization/Dockerfile.new .
docker run --rm hexstrike-ai:graphql-test graphql-inspector --version
docker run --rm hexstrike-ai:graphql-test graphql-scanner --version
```

---

## Phase 4: Apollo Server Decision (1 hour)

### Analysis Required

The Dockerfile currently installs Apollo-related packages via npm. We need to determine:

1. **Are Apollo packages explicitly installed?**
   - Search Dockerfile for "apollo"
   - Check if they're dependencies of other tools

2. **Is Apollo Server actually used?**
   - Check hexstrike_server.py for Apollo usage
   - Check if GraphQL endpoints exist

### Decision Tree

```
Is Apollo explicitly installed?
├─ YES → Proceed with migration to v4
└─ NO → Are they dependencies?
    ├─ YES → Update parent packages
    └─ NO → No action needed
```

### If Migration Needed

**Add to Dockerfile**:
```dockerfile
# Update Apollo Server to v4 (if needed)
RUN npm install -g \
    @apollo/server@latest \
    @apollo/server-plugin-landing-page-graphql-playground@latest
```

**Note**: This requires code changes in any GraphQL server implementation.

---

## Phase 5: Utility Library Updates (1 hour)

### Step 5.1: Remove Deprecated Lodash Utilities

**Analysis**: Check if lodash.* packages are explicitly installed
```bash
grep -n "lodash\." npm-modernization/Dockerfile.new
```

**If found**: Remove from installation list
**If not found**: They're dependencies and will be handled by parent package updates

### Step 5.2: Update Core-js

**Add to Dockerfile**:
```dockerfile
# Update core-js to latest v3
RUN npm install -g core-js@latest
```

### Step 5.3: Update Faker

**Add to Dockerfile**:
```dockerfile
# Update faker to latest version
RUN npm install -g @faker-js/faker@latest
```

---

## Phase 6: Insomnia CLI Strategy (1 hour)

### Decision: KEEP with Monitoring

**Rationale**:
- Tool is referenced in hexstrike_server.py api_tools list
- Removing would break tool availability checks
- No suitable drop-in replacement available

**Action**: Keep current implementation but add monitoring

**Add comment to Dockerfile**:
```dockerfile
# ------------------------------------------------------------------------------
# Stage C: Node.js 18 builder for insomnia-inso (isolated runtime)
# ------------------------------------------------------------------------------
# NOTE: insomnia-inso is deprecated but still required by hexstrike_server.py
# Monitor for alternatives: https://github.com/Kong/insomnia/issues
# Potential replacements: newman + openapi-to-postman, or custom solution
FROM docker.io/node:18-bullseye AS insomnia-node18-builder
```

**Create monitoring task**:
```bash
echo "TODO: Monitor Insomnia alternatives" > npm-modernization/MONITORING.md
echo "- Check Kong/Insomnia repository for updates" >> npm-modernization/MONITORING.md
echo "- Evaluate newman + openapi-to-postman as replacement" >> npm-modernization/MONITORING.md
echo "- Consider custom API testing solution" >> npm-modernization/MONITORING.md
```

---

## Phase 7: Build and Test (3 hours)

### Step 7.1: Build Updated Image

```bash
# Build with new Dockerfile
docker build -t hexstrike-ai:modernized -f npm-modernization/Dockerfile.new .

# Check for deprecation warnings
docker build -t hexstrike-ai:modernized -f npm-modernization/Dockerfile.new . 2>&1 | grep -i "warn deprecated" > npm-modernization/remaining-warnings.txt

# Compare image sizes
docker images hexstrike-ai:before hexstrike-ai:modernized
```

### Step 7.2: Functional Testing

```bash
# Test container starts
docker run --rm hexstrike-ai:modernized echo "Container starts successfully"

# Test Node.js version
docker run --rm hexstrike-ai:modernized node --version

# Test NPM packages
docker run --rm hexstrike-ai:modernized npm list -g --depth=0 > npm-modernization/npm-packages-after.txt

# Test specific tools
docker run --rm hexstrike-ai:modernized graphql-inspector --version
docker run --rm hexstrike-ai:modernized insomnia --version
docker run --rm hexstrike-ai:modernized newman --version
docker run --rm hexstrike-ai:modernized jwt-cracker --help
```

### Step 7.3: Server Testing

```bash
# Start the MCP server
docker run -d --name hexstrike-test -p 8888:8888 hexstrike-ai:modernized

# Wait for startup
sleep 10

# Test health endpoint
curl http://localhost:8888/health

# Test tool availability also via the health endpoint
curl http://localhost:8888/health

# Check logs for errors
docker logs hexstrike-test

# Cleanup
docker stop hexstrike-test
docker rm hexstrike-test
```

### Step 7.4: Integration Testing

Create test script: `npm-modernization/test-integration.sh`

```bash
#!/bin/bash
set -e

echo "Starting integration tests..."

# Start container
docker run -d --name hexstrike-integration -p 8888:8888 hexstrike-ai:modernized
sleep 15

# Test API tools availability
echo "Testing API tools..."
for tool in api-schema-analyzer postman insomnia curl httpie; do
    echo "  Checking $tool..."
    docker exec hexstrike-integration which $tool || echo "  WARNING: $tool not found"
done

# Test GraphQL tools
echo "Testing GraphQL tools..."
docker exec hexstrike-integration graphql-inspector --version
docker exec hexstrike-integration graphql-scanner --version

# Test server endpoints
echo "Testing server endpoints..."
curl -f http://localhost:8888/health || echo "Health check failed"
curl -f http://localhost:8888/api/telemetry || echo "Telemetry endpoint failed"

# Cleanup
docker stop hexstrike-integration
docker rm hexstrike-integration

echo "Integration tests complete!"
```

```bash
chmod +x npm-modernization/test-integration.sh
./npm-modernization/test-integration.sh
```

---

## Phase 8: Documentation (1 hour)

### Step 8.1: Create Change Log

**File**: `npm-modernization/CHANGELOG.md`

```markdown
# NPM Modernization Changelog

## Date: [Current Date]

### Security Updates
- Updated uuid from 3.4.0 to 10.x (CVE fix)
- Updated glob from 7.x to 11.x (CVE fixes)
- Updated tar from 6.2.1 to 7.x (CVE fixes)
- Updated xmldom to @xmldom/xmldom 0.9.x (CVE-2021-21366)

### Package Updates
- Updated @graphql-inspector from 0.5.1 to @graphql-inspector/cli 5.x
- Updated graphql from 14.0.2 to 16.x
- Updated core-js from 2.6.12 to 3.38.x
- Updated @faker-js/faker from 5.5.3 to 9.x

### Packages Kept
- insomnia-inso 3.6.0 (deprecated but required by server)

### Removed Packages
- None (all deprecated packages are dependencies)

### Breaking Changes
- graphql-inspector command changed to graphql-inspector-cli
- Wrapper script updated to maintain compatibility

### Testing Results
- Build time: [X minutes]
- Image size: Before [X GB] → After [Y GB]
- All functional tests passed: [Yes/No]
- Deprecation warnings remaining: [X]
```

### Step 8.2: Update Main Documentation

**File**: `npm-modernization/README.md`

```markdown
# NPM Modernization Project

## Overview
This directory contains all files related to the NPM package modernization effort for the HexStrike AI Docker image.

## Files
- `MODERNIZATION_PLAN.md` - Overall strategy and analysis
- `PACKAGE_REPLACEMENT_MAPPING.md` - Detailed package mappings
- `IMPLEMENTATION_GUIDE.md` - Step-by-step implementation
- `CHANGELOG.md` - Record of changes made
- `Dockerfile.backup` - Original Dockerfile
- `Dockerfile.new` - Updated Dockerfile
- `npm_deprication.txt` - Original deprecation warnings
- `remaining-warnings.txt` - Warnings after modernization
- `test-integration.sh` - Integration test script

## Status
- [x] Planning complete
- [x] Package mapping complete
- [ ] Implementation in progress
- [ ] Testing pending
- [ ] Documentation pending

## Next Steps
1. Review implementation guide
2. Execute Phase 2-7
3. Complete testing
4. Update documentation
5. Deploy to production
```

---

## Phase 9: Deployment (1 hour)

### Step 9.1: Final Validation

```bash
# Run full test suite
./npm-modernization/test-integration.sh

# Compare deprecation warnings
diff npm-modernization/npm_deprication.txt npm-modernization/remaining-warnings.txt

# Verify no critical warnings remain
cat npm-modernization/remaining-warnings.txt | grep -i "critical\|security\|vulnerability"
```

### Step 9.2: Deploy Updated Dockerfile

```bash
# Backup current production Dockerfile
cp docker/Dockerfile docker/Dockerfile.pre-modernization

# Deploy new Dockerfile
cp npm-modernization/Dockerfile.new docker/Dockerfile

# Commit changes
git add docker/Dockerfile npm-modernization/
git commit -m "NPM package modernization - security updates and deprecation fixes"
```

### Step 9.3: Update CI/CD

If using CI/CD, update build pipelines to:
1. Check for new deprecation warnings
2. Run integration tests
3. Compare image sizes
4. Alert on failures

---

## Rollback Procedure

If issues are discovered:

```bash
# Restore original Dockerfile
cp docker/Dockerfile.pre-modernization docker/Dockerfile

# Rebuild
docker build -t hexstrike-ai:rollback -f docker/Dockerfile .

# Test
docker run --rm hexstrike-ai:rollback /usr/local/bin/entrypoint.sh

# Document issue
echo "Rollback performed on $(date)" >> npm-modernization/ROLLBACK_LOG.md
echo "Reason: [describe issue]" >> npm-modernization/ROLLBACK_LOG.md
```

---

## Monitoring and Maintenance

### Weekly Tasks
- Check for new deprecation warnings
- Monitor Insomnia repository for updates
- Review security advisories for installed packages

### Monthly Tasks
- Update packages to latest versions
- Review and update documentation
- Test with latest Docker base images

### Quarterly Tasks
- Full security audit
- Performance benchmarking
- Evaluate new tool alternatives

---

## Success Criteria Checklist

- [ ] Docker image builds without errors
- [ ] No critical deprecation warnings
- [ ] All security vulnerabilities addressed
- [ ] Image size within acceptable range (±10%)
- [ ] All tools in api_tools list functional
- [ ] GraphQL endpoints working
- [ ] Integration tests passing
- [ ] Documentation updated
- [ ] Changes committed to repository
- [ ] Team notified of changes

---

## Troubleshooting

### Issue: Build fails with "module not found"
**Solution**: Check package name changes in PACKAGE_REPLACEMENT_MAPPING.md

### Issue: Tool not found after update
**Solution**: Verify wrapper scripts updated in Phase 3.3

### Issue: Deprecation warnings still present
**Solution**: Check if warnings are from dependencies (acceptable) or direct installs (needs fixing)

### Issue: Image size increased significantly
**Solution**: Review installed packages, remove unused dependencies

### Issue: Server fails to start
**Solution**: Check logs, verify all required tools are available

---

## Contact and Support

For questions or issues:
1. Review this guide and related documentation
2. Check TROUBLESHOOTING section
3. Review git commit history for recent changes
4. Contact team lead or DevOps

---

## Appendix A: Quick Reference Commands

```bash
# Build test image
docker build -t hexstrike-ai:test -f npm-modernization/Dockerfile.new .

# Run integration tests
./npm-modernization/test-integration.sh

# Check deprecation warnings
docker build -t hexstrike-ai:test -f npm-modernization/Dockerfile.new . 2>&1 | grep "warn deprecated"

# List installed packages
docker run --rm hexstrike-ai:test npm list -g --depth=0

# Test specific tool
docker run --rm hexstrike-ai:test [tool-name] --version

# Start server for testing
docker run -d --name test -p 8888:8888 hexstrike-ai:test

# View server logs
docker logs test

# Stop and remove test container
docker stop test && docker rm test
```

---

## Appendix B: Estimated Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Preparation | 30 min | None |
| Security Updates | 2 hours | Preparation |
| GraphQL Tools | 2 hours | Security Updates |
| Apollo Decision | 1 hour | GraphQL Tools |
| Utility Updates | 1 hour | Apollo Decision |
| Insomnia Strategy | 1 hour | Utility Updates |
| Build & Test | 3 hours | All previous |
| Documentation | 1 hour | Build & Test |
| Deployment | 1 hour | Documentation |

**Total**: 12.5 hours (with buffer: 15 hours)

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-22 | Bob (AI Assistant) | Initial implementation guide |