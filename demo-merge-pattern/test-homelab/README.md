# Test Homelab - Manifest Merging Prototype

This prototype demonstrates using the NixOS module system to merge service manifests from public (homelab) and private (private-modules) repositories.

## Architecture

### Discovery (Independent)
- **test-homelab**: Discovers `./services/*/manifest.nix` as unevaluated modules
- **test-private-modules**: Discovers `./services/*/manifest.nix` as unevaluated modules

### Merging (Homelab Flake)
Uses `lib.evalModules` to merge manifests with proper semantics:
- **Lists concatenate**: `dashboard.links`
- **Attrsets union**: `endpoints`
- **Recursive merge**: `observability`
- **Custom merge for `module`**: Singular path syntax, but multiple definitions auto-collect into list
- **Auto-assembly**: `.default` computed from:
  - `module` (collected from all sources)
  - `endpointsModule` (if endpoints.impl exists)
  - `firewallModule` (custom or auto-generated from endpoints)
  - `observabilityImpls` (metrics, logging, probes - NOT alerts)
  - `backups.impl`, `storage.impl`

### Three Service Patterns

1. **Public-only** (`service-c`): Only in test-homelab
   ```nix
   module = ./service.nix;  # Singular syntax!
   endpoints.web = { port = 3000; protocol = "https"; };
   observability.metrics.impl = ./metrics.nix;
   ```
   Result: `default = [ service.nix «auto-firewall» metrics.nix ]`

2. **Private-only** (`service-a`): Only in test-private-modules
   ```nix
   module = ./service.nix;  # Singular syntax!
   endpoints.web = { port = 9001; protocol = "https"; };
   ```
   Result: `default = [ service.nix «auto-firewall» ]`

3. **Mixed** (`service-b`): In both repos, merged together
   - Public: `module = ./service.nix;` (singular!)
   - Private: `module = ./private.nix;` (singular!)
   - Result: `module = [ private.nix service.nix ]` (auto-collected!)
   - Full `.default`: `[ private.nix service.nix «auto-firewall» metrics.nix ]`

## Key Files

- `lib/manifest-options.nix` - NixOS module schema for manifests
- `lib/merge-manifests.nix` - evalModules-based merge logic
- `flake.nix` - Discovers, merges, exports as `serviceModules`

## Testing

```bash
# Show discovered services
nix eval .#lib.debug.mergedServiceNames

# Inspect merged manifest
nix eval .#serviceModules.service-b

# Check auto-assembled modules
nix eval .#serviceModules.service-b.default
```

## Benefits

- ✅ Leverage NixOS module system for merging (battle-tested)
- ✅ Type safety via options
- ✅ Automatic list concatenation, attrset merging
- ✅ **Singular `module` syntax** with custom merge (no conflicts!)
- ✅ **Auto-generated firewall** from endpoints (matches current homelab)
- ✅ **Local concerns only** in `.default` (no remote grafana/prometheus configs)
- ✅ Deferred evaluation (manifests stay as functions until merge)
- ✅ Auto-assembly of `.default` from components
- ✅ Source tracking for debug (`_sources.hasPublic/hasPrivate`)
- ✅ Consumers get fixed-point evaluated attrsets

## Migration Path

1. Add `lib/manifest-options.nix` to homelab-subflake (with custom modulePathType)
2. Add `lib/merge-manifests.nix` to homelab-subflake (with auto-assembly logic)
3. Update `flake.nix` to merge with private-modules.serviceModules
4. **No manifest changes needed** - `module = ./path` syntax already works!
5. Update consumers (ssl-proxy, prometheus) to use merged `serviceModules`
6. Ensure private-modules exports unevaluated manifest modules
