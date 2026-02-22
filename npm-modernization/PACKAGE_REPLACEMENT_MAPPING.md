# NPM Package Replacement Mapping

## Overview
This document provides a detailed mapping of deprecated NPM packages to their modern alternatives, including version constraints, breaking changes, and migration notes.

---

## Critical Replacements

### 1. Insomnia CLI Suite

| Old Package | Version | New Package | Version | Status | Notes |
|------------|---------|-------------|---------|--------|-------|
| `insomnia-inso` | 3.6.0 | **KEEP** | 3.6.0 | ⚠️ Required | Used in api_tools list in hexstrike_server.py. Keep isolated Node 18 runtime. |

**Decision**: KEEP - The tool is referenced in the server's tool availability checks. Removing would break functionality.

**Alternative Strategy**: 
- Keep the isolated Node 18 builder stage
- Update to latest compatible version if available
- Monitor for community forks or alternatives

---

## High Priority - Security Updates

### 2. UUID Library

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `uuid` | 3.4.0 | `uuid` | 10.0.0 | ✅ None - Drop-in replacement |

**Security Issue**: CVE - Math.random() usage in older versions
**Migration**: Simple version bump
```bash
npm install -g uuid@latest
```

### 3. Glob Library

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `glob` | 7.x | `glob` | 11.0.0 | ⚠️ Minor API changes |

**Security Issue**: Multiple CVEs in versions < 8.0
**Migration**: Update to latest version
```bash
npm install -g glob@latest
```

### 4. XMLDom Library

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `xmldom` | 0.1.31 | `@xmldom/xmldom` | 0.9.0 | ⚠️ Package name change |

**Security Issue**: CVE-2021-21366
**Migration**: Update package name and version
```bash
npm install -g @xmldom/xmldom@latest
```

### 5. Tar Library

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `tar` | 6.2.1 | `tar` | 7.4.3 | ⚠️ Minor API changes |

**Security Issue**: Multiple CVEs
**Migration**: Version bump
```bash
npm install -g tar@latest
```

---

## Apollo Server Migration (High Priority)

### 6. Apollo Server Core

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `apollo-server` | 2.2.2 | `@apollo/server` | 4.11.0 | ❌ Major breaking changes |
| `apollo-server-express` | 2.2.2 | `@apollo/server` + `@apollo/server/express4` | 4.11.0 | ❌ Major breaking changes |
| `apollo-server-core` | 2.2.2 | `@apollo/server` | 4.11.0 | ❌ Major breaking changes |

**EOL Date**: October 22, 2024
**Migration Complexity**: High

**Breaking Changes**:
1. Package namespace changed from `apollo-server-*` to `@apollo/server`
2. Express integration now separate package
3. Plugin API completely redesigned
4. Context function signature changed
5. Startup method changed from `listen()` to `start()`

**Migration Steps**:
```bash
# Remove old packages
npm uninstall -g apollo-server apollo-server-express apollo-server-core

# Install new packages
npm install -g @apollo/server@latest
```

**Code Changes Required**:
```javascript
// OLD (v2)
const { ApolloServer } = require('apollo-server-express');
const server = new ApolloServer({ typeDefs, resolvers });
await server.start();
server.applyMiddleware({ app });

// NEW (v4)
const { ApolloServer } = require('@apollo/server');
const { expressMiddleware } = require('@apollo/server/express4');
const server = new ApolloServer({ typeDefs, resolvers });
await server.start();
app.use('/graphql', expressMiddleware(server));
```

### 7. Apollo Plugins & Extensions

| Old Package | Version | New Package | Version | Status |
|------------|---------|-------------|---------|--------|
| `apollo-server-plugin-base` | 0.1.2 | Built into `@apollo/server` | 4.x | ✅ Integrated |
| `apollo-server-errors` | 2.2.0 | Built into `@apollo/server` | 4.x | ✅ Integrated |
| `apollo-cache-control` | 0.3.2 | Built into `@apollo/server` | 4.x | ✅ Integrated |
| `apollo-tracing` | 0.3.2 | `@apollo/server-plugin-response-cache` | 4.x | ⚠️ Replaced |
| `graphql-extensions` | 0.3.2 | Plugin API | 4.x | ❌ Removed |

**Migration**: Most functionality is now built-in or available via new plugin API

### 8. Apollo Data Sources & Caching

| Old Package | Version | New Package | Version | Status |
|------------|---------|-------------|---------|--------|
| `apollo-datasource` | 0.2.0 | `@apollo/datasource-rest` | 6.x | ⚠️ Separate package |
| `apollo-server-caching` | 0.2.0 | `@apollo/utils.keyvaluecache` | 3.x | ⚠️ Keyv-based |
| `apollo-server-env` | 2.2.0 | `@apollo/utils.fetcher` | 3.x | ⚠️ Replaced |

**Migration**: 
```bash
npm install -g @apollo/datasource-rest@latest @apollo/utils.keyvaluecache@latest
```

---

## GraphQL Tools Migration (High Priority)

### 9. GraphQL Tools

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `graphql-tools` | 4.0.8 | `@graphql-tools/schema` | 10.x | ⚠️ Scoped packages |
| | | `@graphql-tools/utils` | 10.x | |
| | | `@graphql-tools/merge` | 9.x | |

**Migration**:
```bash
npm uninstall -g graphql-tools
npm install -g @graphql-tools/schema@latest @graphql-tools/utils@latest @graphql-tools/merge@latest
```

**Code Changes**:
```javascript
// OLD
const { makeExecutableSchema } = require('graphql-tools');

// NEW
const { makeExecutableSchema } = require('@graphql-tools/schema');
```

### 10. GraphQL Core

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `graphql` | 14.0.2 | `graphql` | 16.9.0 | ⚠️ Minor API changes |

**Migration**:
```bash
npm install -g graphql@16
```

### 11. GraphQL Inspector

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `graphql-inspector` | 0.5.1 | `@graphql-inspector/cli` | 5.x | ⚠️ Package name change |

**Migration**:
```bash
npm uninstall -g graphql-inspector
npm install -g @graphql-inspector/cli@latest
```

---

## WebSocket & Subscriptions (Medium Priority)

### 12. GraphQL Subscriptions

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `subscriptions-transport-ws` | 0.9.19 | `graphql-ws` | 5.16.0 | ❌ Protocol change |

**Migration Complexity**: Medium
**Migration Guide**: https://www.apollographql.com/docs/apollo-server/data/subscriptions/#switching-from-subscriptions-transport-ws

```bash
npm uninstall -g subscriptions-transport-ws
npm install -g graphql-ws@latest
```

---

## Utility Libraries (Medium Priority)

### 13. HTTP Request Library

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `request` | 2.88.2 | `axios` | 1.7.7 | ❌ Different API |

**Migration**:
```bash
npm uninstall -g request
npm install -g axios@latest
```

**Code Changes**:
```javascript
// OLD (request)
request('http://example.com', (error, response, body) => {
  console.log(body);
});

// NEW (axios)
const response = await axios.get('http://example.com');
console.log(response.data);
```

### 14. Lodash Utilities

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `lodash.isequal` | 4.5.0 | Native Node.js | - | ✅ Use `util.isDeepStrictEqual()` |
| `lodash.get` | 4.4.2 | Native JavaScript | - | ✅ Use optional chaining `?.` |

**Migration**:
```bash
npm uninstall -g lodash.isequal lodash.get
```

**Code Changes**:
```javascript
// OLD (lodash.isequal)
const isEqual = require('lodash.isequal');
isEqual(obj1, obj2);

// NEW (native)
const { isDeepStrictEqual } = require('node:util');
isDeepStrictEqual(obj1, obj2);

// OLD (lodash.get)
const get = require('lodash.get');
const value = get(obj, 'path.to.property', 'default');

// NEW (native)
const value = obj?.path?.to?.property ?? 'default';
```

### 15. Promise Library

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `q` | 1.5.1 | Native Promises | - | ✅ Use native `Promise` |

**Migration**:
```bash
npm uninstall -g q
```

**Code Changes**:
```javascript
// OLD (Q)
const Q = require('q');
const deferred = Q.defer();
deferred.resolve(value);
return deferred.promise;

// NEW (native)
return Promise.resolve(value);
```

### 16. JSON Schema Parser

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `json-schema-ref-parser` | 7.1.4 | `@apidevtools/json-schema-ref-parser` | 11.7.0 | ⚠️ Package name change |

**Migration**:
```bash
npm uninstall -g json-schema-ref-parser
npm install -g @apidevtools/json-schema-ref-parser@latest
```

---

## Build Tools (Low Priority)

### 17. File System Utilities

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `rimraf` | 3.0.2 | `rimraf` | 6.0.1 | ⚠️ API changes |
| `mkdirp-promise` | 1.1.0 | Native `mkdirp` | - | ✅ Built-in promises |
| `inflight` | 1.0.6 | `lru-cache` | 11.x | ❌ Different purpose |

**Migration**:
```bash
npm install -g rimraf@latest
npm uninstall -g mkdirp-promise inflight
```

**Code Changes**:
```javascript
// OLD (mkdirp-promise)
const mkdirp = require('mkdirp-promise');
await mkdirp('/path/to/dir');

// NEW (native mkdirp)
const mkdirp = require('mkdirp');
await mkdirp('/path/to/dir'); // Already returns a promise
```

### 18. Validation Libraries

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `har-validator` | 5.1.5 | Remove | - | ⚠️ No longer needed |

**Migration**: Remove if not critical
```bash
npm uninstall -g har-validator
```

---

## Monitoring & Logging (Low Priority)

### 19. Progress & Logging

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `npmlog` | 4.1.2 | `pino` | 9.x | ❌ Different API |
| `are-we-there-yet` | 1.1.7 | Remove | - | ⚠️ No longer needed |
| `gauge` | 2.7.4 | Remove | - | ⚠️ No longer needed |

**Migration**:
```bash
npm uninstall -g npmlog are-we-there-yet gauge
npm install -g pino@latest  # Optional, if logging needed
```

---

## Legacy Dependencies (Low Priority)

### 20. Core-js

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `core-js` | 2.6.12 | `core-js` | 3.38.1 | ⚠️ Import paths changed |

**Migration**:
```bash
npm install -g core-js@latest
```

**Breaking Changes**: Import paths changed from `core-js/library/*` to `core-js/*`

### 21. Swagger/OpenAPI

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `swagger-methods` | 2.0.2 | Remove | - | ⚠️ No longer maintained |
| `apiconnect-wsdl` | 1.8.31 | Remove | - | ⚠️ No longer supported |

**Migration**: Remove if not critical

### 22. Faker

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `@faker-js/faker` | 5.5.3 | `@faker-js/faker` | 9.0.3 | ⚠️ API changes |

**Migration**:
```bash
npm install -g @faker-js/faker@latest
```

### 23. MUI Base

| Old Package | Version | New Package | Version | Breaking Changes |
|------------|---------|-------------|---------|------------------|
| `@mui/base` | 5.0.0-beta.40 | `@base-ui/react` | 1.x | ❌ Complete rewrite |

**Migration**: Only if UI components are used
```bash
npm uninstall -g @mui/base
npm install -g @base-ui/react@latest
```

---

## Summary Statistics

### By Priority

| Priority | Packages | Action Required |
|----------|----------|-----------------|
| Critical | 1 | Keep (Insomnia) |
| High | 15 | Update/Replace |
| Medium | 8 | Update/Replace |
| Low | 9 | Update/Remove |

### By Action Type

| Action | Count | Examples |
|--------|-------|----------|
| Version Bump | 8 | uuid, glob, tar, graphql |
| Package Rename | 5 | @apollo/server, @xmldom/xmldom |
| Replace with Native | 4 | lodash.*, q, mkdirp-promise |
| Remove | 6 | har-validator, npmlog, gauge |
| Keep | 1 | insomnia-inso |

### Risk Assessment

| Risk Level | Count | Mitigation |
|------------|-------|------------|
| High | 3 | Thorough testing, staged rollout |
| Medium | 8 | Integration testing |
| Low | 12 | Standard testing |

---

## Implementation Order

1. **Phase 1**: Security updates (uuid, glob, tar, xmldom)
2. **Phase 2**: Simple version bumps (graphql, faker, core-js)
3. **Phase 3**: Package renames (@graphql-tools/*, @apidevtools/*)
4. **Phase 4**: Native replacements (lodash.*, q, mkdirp-promise)
5. **Phase 5**: Complex migrations (Apollo Server, graphql-ws)
6. **Phase 6**: Removals (har-validator, npmlog, etc.)
7. **Phase 7**: Testing and validation

---

## Testing Checklist

After each phase:
- [ ] Docker image builds successfully
- [ ] No deprecation warnings in build logs
- [ ] All tools in api_tools list are available
- [ ] GraphQL endpoints respond correctly
- [ ] API testing workflows function properly
- [ ] No runtime errors in logs
- [ ] Performance benchmarks maintained

---

## Rollback Procedures

If issues arise:
1. Restore `Dockerfile.backup`
2. Rebuild image: `docker build -t hexstrike-ai:rollback .`
3. Test with: `docker run hexstrike-ai:rollback`
4. Document issues in `ROLLBACK_LOG.md`

---

## References

- [Apollo Server v4 Migration Guide](https://www.apollographql.com/docs/apollo-server/migration/)
- [GraphQL Tools Migration](https://www.graphql-tools.com/docs/migration/migration-from-tools-v5)
- [graphql-ws Migration](https://github.com/enisdenjo/graphql-ws#migrating-from-subscriptions-transport-ws)
- [Node.js Deprecations](https://nodejs.org/api/deprecations.html)