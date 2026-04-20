# NPM Package Modernization Plan for HexStrike AI Docker

## Executive Summary

This document outlines the strategy for modernizing deprecated NPM packages in the HexStrike AI Docker image. The goal is to replace outdated packages with modern alternatives while maintaining full functionality of the hexstrike-ai MCP server.

## Current State Analysis

### Deprecated Packages Identified

Based on `npm_deprication.txt`, the following categories of deprecated packages were found:

#### 1. **Insomnia CLI Suite (CRITICAL - No longer maintained)**
- `insomnia-inso@3.6.0` - Main CLI tool
- All insomnia plugins and dependencies (20+ packages)
- **Impact**: High - Used for API testing and reconnaissance
- **Status**: Package no longer supported by Kong

#### 2. **Apollo Server v2 (END-OF-LIFE)**
- `apollo-server@2.2.2`
- `apollo-server-express@2.2.2`
- `apollo-server-core@2.2.2`
- `apollo-server-env@2.2.0`
- `apollo-server-errors@2.2.0`
- `apollo-server-plugin-base@0.1.2`
- `apollo-datasource@0.2.0`
- `apollo-cache-control@0.3.2`
- `apollo-server-caching@0.2.0`
- `apollo-tracing@0.3.2`
- **Impact**: High - GraphQL server functionality
- **EOL Date**: October 22, 2024

#### 3. **GraphQL Tools (Deprecated)**
- `graphql-tools@4.0.8` - Deprecated, use scoped packages
- `graphql@14.0.2` - No longer supported
- `graphql-extensions@0.3.2` - Removed from Apollo Server 3
- `graphql-inspector@0.5.1` - Use `@graphql-inspector/cli`
- **Impact**: Medium - GraphQL schema analysis

#### 4. **Utility Libraries**
- `lodash.isequal@4.5.0` - Use `node:util.isDeepStrictEqual`
- `lodash.get@4.4.2` - Use optional chaining operator (?.)
- `uuid@3.4.0` - Upgrade to v7+ (security issue)
- `request@2.88.2` - Deprecated, use `axios` or `node-fetch`
- `q@1.5.1` - Use native Promises
- **Impact**: Low - Can be replaced with native Node.js features

#### 5. **File System & Build Tools**
- `glob@7.x` - Security vulnerabilities, upgrade to latest
- `rimraf@3.0.2` - Upgrade to v4+
- `tar@6.2.1` - Security vulnerabilities, upgrade to latest
- `inflight@1.0.6` - Memory leak, use `lru-cache`
- `mkdirp-promise@1.1.0` - Use native `mkdirp` with promises
- **Impact**: Low - Build-time dependencies

#### 6. **Validation & Parsing**
- `har-validator@5.1.5` - No longer supported
- `xmldom@0.1.31` - CVE-2021-21366, upgrade to 0.5.0+
- `json-schema-ref-parser@7.1.4` - Use `@apidevtools/json-schema-ref-parser`
- **Impact**: Medium - Data validation

#### 7. **Monitoring & Logging**
- `npmlog@4.1.2` - No longer supported
- `are-we-there-yet@1.1.7` - No longer supported
- `gauge@2.7.4` - No longer supported
- **Impact**: Low - Progress reporting

#### 8. **WebSocket & Subscriptions**
- `subscriptions-transport-ws@0.9.19` - Use `graphql-ws`
- **Impact**: Medium - Real-time GraphQL subscriptions

#### 9. **Legacy Dependencies**
- `core-js@2.6.12` - Performance issues, upgrade to 3.23.3+
- `swagger-methods@2.0.2` - No longer maintained
- `apiconnect-wsdl@1.8.31` - No longer supported
- **Impact**: Low-Medium

#### 10. **UI Components**
- `@mui/base@5.0.0-beta.40` - Replaced by `@base-ui/react`
- `@faker-js/faker@5.5.3` - Update to newer version
- **Impact**: Low - If used in UI components

## Modernization Strategy

### Phase 1: Critical Replacements (High Priority)

#### 1.1 Insomnia CLI Replacement
**Current**: `insomnia-inso@3.6.0` (Node 18 isolated runtime)
**Options**:
- **Option A**: Remove entirely if not critical to functionality
- **Option B**: Replace with `@apideck/portman` (Postman to OpenAPI converter)
- **Option C**: Use `newman` (already installed) + `openapi-to-postman`
- **Recommendation**: Option C - Leverage existing Newman installation

**Implementation**:
```dockerfile
# Remove insomnia-node18-builder stage entirely
# Add openapi-to-postman converter
RUN npm install -g openapi-to-postman
```

#### 1.2 Apollo Server Migration
**Current**: Apollo Server v2.2.2
**Target**: `@apollo/server@4.x` (latest)

**Breaking Changes**:
- Package name changed from `apollo-server` to `@apollo/server`
- Express integration now via `@apollo/server/express4`
- Plugin API completely redesigned
- Cache implementation changed to Keyv-based

**Implementation**:
```dockerfile
RUN npm install -g \
    @apollo/server@latest \
    @apollo/server-plugin-landing-page-graphql-playground@latest \
    graphql@16.x
```

#### 1.3 GraphQL Tools Update
**Current**: `graphql-tools@4.0.8`
**Target**: Scoped packages

**Implementation**:
```dockerfile
RUN npm install -g \
    @graphql-tools/schema@latest \
    @graphql-tools/utils@latest \
    @graphql-tools/merge@latest \
    @graphql-inspector/cli@latest
```

### Phase 2: Security Updates (High Priority)

#### 2.1 UUID Update
**Current**: `uuid@3.4.0`
**Target**: `uuid@10.x` (latest)
**Reason**: Math.random() security issue

#### 2.2 Glob Update
**Current**: `glob@7.x`
**Target**: `glob@11.x` (latest)
**Reason**: Security vulnerabilities

#### 2.3 XMLDom Update
**Current**: `xmldom@0.1.31`
**Target**: `@xmldom/xmldom@0.9.x`
**Reason**: CVE-2021-21366

#### 2.4 Tar Update
**Current**: `tar@6.2.1`
**Target**: `tar@7.x` (latest)
**Reason**: Security vulnerabilities

### Phase 3: Utility Replacements (Medium Priority)

#### 3.1 Request Replacement
**Current**: `request@2.88.2`
**Options**:
- `axios@1.x` - Most popular, feature-rich
- `node-fetch@3.x` - Minimal, fetch API compatible
- `got@14.x` - Modern, TypeScript-first
**Recommendation**: `axios` for compatibility

#### 3.2 Lodash Utilities
**Current**: `lodash.isequal`, `lodash.get`
**Target**: Native JavaScript
- `lodash.isequal` → `util.isDeepStrictEqual()` (Node.js built-in)
- `lodash.get` → Optional chaining (`?.`)

#### 3.3 Promise Library
**Current**: `q@1.5.1`
**Target**: Native Promises (no package needed)

#### 3.4 JSON Schema Parser
**Current**: `json-schema-ref-parser@7.1.4`
**Target**: `@apidevtools/json-schema-ref-parser@11.x`

### Phase 4: Build Tool Updates (Low Priority)

#### 4.1 File System Tools
- `rimraf@3.0.2` → `rimraf@6.x`
- `mkdirp-promise@1.1.0` → Remove (use native `mkdirp`)
- `inflight@1.0.6` → Remove (use `lru-cache` if needed)

#### 4.2 Monitoring Tools
- `npmlog@4.1.2` → Remove or use `pino` for logging
- `are-we-there-yet@1.1.7` → Remove
- `gauge@2.7.4` → Remove

### Phase 5: WebSocket & Subscriptions (Medium Priority)

#### 5.1 GraphQL Subscriptions
**Current**: `subscriptions-transport-ws@0.9.19`
**Target**: `graphql-ws@5.x`

**Migration Guide**: https://www.apollographql.com/docs/apollo-server/data/subscriptions/#switching-from-subscriptions-transport-ws

### Phase 6: Legacy Dependencies (Low Priority)

#### 6.1 Core-js Update
**Current**: `core-js@2.6.12`
**Target**: `core-js@3.38.x` (latest)
**Reason**: Performance improvements, bug fixes

#### 6.2 Faker Update
**Current**: `@faker-js/faker@5.5.3`
**Target**: `@faker-js/faker@9.x` (latest)

#### 6.3 MUI Base Update
**Current**: `@mui/base@5.0.0-beta.40`
**Target**: `@base-ui/react@latest`

## Implementation Plan

### Step 1: Backup Current Configuration
```bash
cp docker/Dockerfile npm-modernization/Dockerfile.backup
cp docker/docker-compose.yml npm-modernization/docker-compose.yml.backup
```

### Step 2: Create Updated Dockerfile

The updated Dockerfile will:
1. Remove the `insomnia-node18-builder` stage (lines 52-81)
2. Update NPM global installations (lines 554-561)
3. Remove insomnia-related wrappers (lines 752-753)
4. Add modern package alternatives

### Step 3: Package Replacement Mapping

Create a detailed mapping document showing:
- Old package → New package
- Version constraints
- Breaking changes
- Migration notes

### Step 4: Testing Strategy

1. **Build Test**: Verify Docker image builds successfully
2. **Functionality Test**: Verify all MCP server tools work
3. **Integration Test**: Test with actual security scanning workflows
4. **Performance Test**: Compare performance before/after

### Step 5: Rollback Plan

- Keep original Dockerfile as `Dockerfile.backup`
- Document all changes in `CHANGES.md`
- Create rollback script if needed

## Risk Assessment

### High Risk Changes
1. **Insomnia CLI Removal**: May break API testing workflows
   - **Mitigation**: Verify usage in hexstrike_server.py first
   - **Alternative**: Keep if critical, update to latest compatible version

2. **Apollo Server Migration**: Breaking API changes
   - **Mitigation**: Thorough testing of GraphQL endpoints
   - **Alternative**: Pin to Apollo Server v3 (still supported until Oct 2024)

### Medium Risk Changes
1. **GraphQL Tools Update**: API changes in scoped packages
2. **Request → Axios**: Different API surface
3. **WebSocket Library**: Subscription protocol changes

### Low Risk Changes
1. **Utility Libraries**: Drop-in replacements or native features
2. **Build Tools**: Build-time only, no runtime impact
3. **Version Bumps**: Backward compatible updates

## Success Criteria

1. ✅ Docker image builds without errors
2. ✅ All security tools remain functional
3. ✅ No deprecated package warnings in build logs
4. ✅ MCP server starts and responds correctly
5. ✅ All API endpoints work as expected
6. ✅ Performance is maintained or improved
7. ✅ Security vulnerabilities are resolved

## Timeline Estimate

- **Phase 1 (Critical)**: 2-3 hours
- **Phase 2 (Security)**: 1-2 hours
- **Phase 3 (Utilities)**: 1-2 hours
- **Phase 4 (Build Tools)**: 1 hour
- **Phase 5 (WebSocket)**: 1-2 hours
- **Phase 6 (Legacy)**: 1 hour
- **Testing**: 2-3 hours
- **Documentation**: 1 hour

**Total Estimated Time**: 10-15 hours

## Next Steps

1. Review this plan with stakeholders
2. Verify Insomnia CLI usage in codebase
3. Create package replacement mapping document
4. Begin Phase 1 implementation
5. Test incrementally after each phase

## References

- [Apollo Server Migration Guide](https://www.apollographql.com/docs/apollo-server/migration/)
- [GraphQL Tools Migration](https://www.graphql-tools.com/docs/migration/migration-from-tools-v5)
- [Node.js Fetch API](https://nodejs.org/dist/latest-v18.x/docs/api/globals.html#fetch)
- [UUID Security Advisory](https://github.com/uuidjs/uuid#getrandomvalues-not-supported)