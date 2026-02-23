# NPM Modernization Project

## Overview
This directory contains all documentation and resources for modernizing deprecated NPM packages in the HexStrike AI Docker image. The goal is to eliminate security vulnerabilities and deprecation warnings while maintaining full functionality.

---

## Project Status

**Current Phase**: Planning Complete ✅

**Next Phase**: Ready for Implementation

---

## Quick Start

### For Reviewers
1. Read `MODERNIZATION_PLAN.md` for strategy overview
2. Review `PACKAGE_REPLACEMENT_MAPPING.md` for detailed changes
3. Check `IMPLEMENTATION_GUIDE.md` for execution steps

### For Implementers
1. Follow `IMPLEMENTATION_GUIDE.md` step-by-step
2. Reference `PACKAGE_REPLACEMENT_MAPPING.md` for specific package changes
3. Use provided test scripts for validation

---

## Directory Structure

```
npm-modernization/
├── README.md                           # This file
├── MODERNIZATION_PLAN.md               # Strategic overview and analysis
├── PACKAGE_REPLACEMENT_MAPPING.md      # Detailed package mappings
├── IMPLEMENTATION_GUIDE.md             # Step-by-step implementation
├── npm_deprication.txt                 # Original deprecation warnings (43 lines)
├── Dockerfile.backup                   # Original Dockerfile (to be created)
├── Dockerfile.new                      # Updated Dockerfile (to be created)
├── docker-compose.yml.backup           # Original compose file (to be created)
├── requirements.txt.backup             # Original requirements (to be created)
├── CHANGELOG.md                        # Change log (to be created)
├── MONITORING.md                       # Ongoing monitoring tasks (to be created)
├── test-integration.sh                 # Integration test script (to be created)
├── npm-packages-before.txt             # Package list before changes (to be created)
├── npm-packages-after.txt              # Package list after changes (to be created)
├── remaining-warnings.txt              # Warnings after modernization (to be created)
└── ROLLBACK_LOG.md                     # Rollback history if needed (to be created)
```

---

## Key Documents

### 1. MODERNIZATION_PLAN.md
**Purpose**: Strategic overview and risk assessment
**Key Sections**:
- Current state analysis
- Deprecated packages by category
- Modernization strategy by phase
- Risk assessment
- Success criteria
- Timeline estimates

**Read this first** to understand the overall approach.

### 2. PACKAGE_REPLACEMENT_MAPPING.md
**Purpose**: Detailed package-by-package mapping
**Key Sections**:
- Old package → New package mappings
- Version constraints
- Breaking changes
- Migration code examples
- Testing procedures

**Use this** as a reference during implementation.

### 3. IMPLEMENTATION_GUIDE.md
**Purpose**: Step-by-step execution instructions
**Key Sections**:
- Phase-by-phase implementation
- Build and test procedures
- Deployment steps
- Rollback procedures
- Troubleshooting guide

**Follow this** to execute the modernization.

---

## Summary of Changes

### Packages to Update (15)
- `uuid`: 3.4.0 → 10.x (Security: CVE fix)
- `glob`: 7.x → 11.x (Security: Multiple CVEs)
- `tar`: 6.2.1 → 7.x (Security: Multiple CVEs)
- `xmldom`: 0.1.31 → @xmldom/xmldom 0.9.x (Security: CVE-2021-21366)
- `graphql-inspector`: 0.5.1 → @graphql-inspector/cli 5.x
- `graphql`: 14.0.2 → 16.x
- `core-js`: 2.6.12 → 3.38.x
- `@faker-js/faker`: 5.5.3 → 9.x
- Plus 7 more utility and build tool updates

### Packages to Keep (1)
- `insomnia-inso`: 3.6.0 (Deprecated but required by server)

### Packages to Remove (6)
- `har-validator`, `npmlog`, `are-we-there-yet`, `gauge`, and others
- (Most are dependencies, not directly installed)

---

## Risk Assessment

### High Risk (3 packages)
- Apollo Server migration (if needed)
- GraphQL subscriptions (protocol change)
- Request → Axios (API change)

**Mitigation**: Thorough testing, staged rollout

### Medium Risk (8 packages)
- GraphQL tools (scoped package changes)
- JSON schema parser (package rename)
- WebSocket libraries

**Mitigation**: Integration testing

### Low Risk (12 packages)
- Version bumps (backward compatible)
- Native replacements (lodash.*, q)
- Build tools (build-time only)

**Mitigation**: Standard testing

---

## Implementation Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| Planning | 3 hours | ✅ Complete |
| Preparation | 30 min | ⏳ Pending |
| Security Updates | 2 hours | ⏳ Pending |
| GraphQL Tools | 2 hours | ⏳ Pending |
| Apollo Decision | 1 hour | ⏳ Pending |
| Utility Updates | 1 hour | ⏳ Pending |
| Insomnia Strategy | 1 hour | ⏳ Pending |
| Build & Test | 3 hours | ⏳ Pending |
| Documentation | 1 hour | ⏳ Pending |
| Deployment | 1 hour | ⏳ Pending |

**Total Estimated**: 15 hours (12.5 hours + 2.5 hour buffer)

---

## Success Criteria

- [x] Planning documentation complete
- [ ] Docker image builds without errors
- [ ] No critical deprecation warnings
- [ ] All security vulnerabilities addressed
- [ ] Image size within acceptable range (±10%)
- [ ] All tools in api_tools list functional
- [ ] GraphQL endpoints working (if applicable)
- [ ] Integration tests passing
- [ ] Documentation updated
- [ ] Changes committed to repository

---

## Key Findings

### Critical Discovery
**Insomnia CLI** (`insomnia-inso@3.6.0`) is deprecated but **must be kept** because:
- Referenced in `hexstrike_server.py` api_tools list
- No suitable drop-in replacement available
- Removing would break tool availability checks

**Strategy**: Keep with monitoring for future alternatives

### Security Priorities
1. **UUID** (CVE - Math.random() vulnerability)
2. **Glob** (Multiple CVEs)
3. **Tar** (Multiple CVEs)
4. **XMLDom** (CVE-2021-21366)

### Low-Impact Changes
- Most deprecated packages are **dependencies**, not directly installed
- Updates will happen automatically when parent packages are updated
- Minimal code changes required

---

## Testing Strategy

### 1. Build Testing
```bash
docker build -t hexstrike-ai:test -f npm-modernization/Dockerfile.new .
```

### 2. Functional Testing
```bash
# Test tool availability
docker run --rm hexstrike-ai:test graphql-inspector --version
docker run --rm hexstrike-ai:test insomnia --version
docker run --rm hexstrike-ai:test newman --version
```

### 3. Integration Testing
```bash
# Run full integration test suite
./npm-modernization/test-integration.sh
```

### 4. Server Testing
```bash
# Start server and test endpoints
docker run -d --name test -p 8888:8888 hexstrike-ai:test
# The health endpoint also returns tool availability
curl http://localhost:8888/health

```

---

## Rollback Plan

If issues arise:

```bash
# Restore original Dockerfile
cp docker/Dockerfile.pre-modernization docker/Dockerfile

# Rebuild
docker build -t hexstrike-ai:rollback -f docker/Dockerfile .

# Document issue
echo "Rollback: $(date) - [reason]" >> npm-modernization/ROLLBACK_LOG.md
```

---

## Next Steps

### Immediate Actions
1. ✅ Review planning documents
2. ⏳ Get stakeholder approval
3. ⏳ Schedule implementation window
4. ⏳ Prepare testing environment

### Implementation Phase
1. Execute Phase 2-7 from IMPLEMENTATION_GUIDE.md
2. Run comprehensive tests
3. Document results
4. Deploy to production

### Post-Implementation
1. Monitor for issues
2. Update documentation
3. Schedule regular package updates
4. Monitor Insomnia alternatives

---

## Important Notes

### About Insomnia CLI
- **Status**: Deprecated by Kong (no longer maintained)
- **Action**: Keep current version (3.6.0)
- **Reason**: Required by hexstrike_server.py
- **Future**: Monitor for alternatives or plan custom solution

### About Apollo Server
- **Status**: v2 is EOL (October 22, 2024)
- **Action**: Determine if actually used, then decide on migration
- **Complexity**: High (breaking changes)
- **Alternative**: May not be needed if not explicitly used

### About Dependencies
- Most deprecated packages are **transitive dependencies**
- They will update automatically when parent packages update
- Focus on **directly installed** packages first

---

## Resources

### External Documentation
- [Apollo Server v4 Migration](https://www.apollographql.com/docs/apollo-server/migration/)
- [GraphQL Tools Migration](https://www.graphql-tools.com/docs/migration/migration-from-tools-v5)
- [Node.js Deprecations](https://nodejs.org/api/deprecations.html)
- [NPM Security Advisories](https://www.npmjs.com/advisories)

### Internal Documentation
- Original deprecation warnings: `npm_deprication.txt`
- Current Dockerfile: `../docker/Dockerfile`
- Server code: `../hexstrike_server.py`

---

## Contact

For questions or issues:
1. Review documentation in this directory
2. Check IMPLEMENTATION_GUIDE.md troubleshooting section
3. Review git commit history
4. Contact project maintainer

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-22 | Bob (AI Assistant) | Initial planning documentation |

---

## License

This documentation is part of the HexStrike AI project.
See main repository for license information.