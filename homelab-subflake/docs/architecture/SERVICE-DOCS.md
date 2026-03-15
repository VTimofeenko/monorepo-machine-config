# Service Documentation Guidelines

## Overview

Each service can include a `README.md` in its directory, referenced via the
`documentation` field in `manifest.nix`. This documentation will be later
consumed by the mdbook pipeline to generate user-facing service documentation.

## What to Document

Service documentation should focus on:

### Purpose and Overview

- **What** the service does (high-level description)
- **Why** it exists in the homelab
- **Key features** that aren't obvious from the manifest

### Usage and Examples

- **Quick start** code snippets (minimal, 1-3 examples max)
- **Links to upstream documentation** instead of duplicating detailed usage
- **Homelab-specific integration patterns** (only if non-standard)

Keep this section short. For standard tools (Gitea, Nextcloud, etc.), just
link to official docs rather than rewriting usage guides.

### Implementation Details

- **Architecture decisions** specific to this service
- **Quirks or gotchas** that operators should know
- **Migration notes** if service was refactored

Avoid duplicating troubleshooting steps from upstream docs. Link instead.

## What NOT to Document

The following information is **auto-discoverable** from the manifest and
service metadata. Do NOT duplicate this in README.md:

### Network Configuration

- **Ports** - defined in `manifest.endpoints`
- **Protocols** - defined in `manifest.endpoints`
- **Network placement** (backbone-inner, LAN) - inferred from endpoints
- **Firewall rules** - auto-generated from endpoints

### Integration Metadata

- **Dashboard links** - defined in `manifest.dashboard`
- **Dashboard category** - defined in `manifest.dashboard`
- **SSL proxy configuration** - defined in `manifest.sslProxyConfig`
- **Metrics endpoints** - defined in `manifest.observability.metrics`

### Service Dependencies

- **Consumers** (who depends on this service) - discoverable by scanning all manifests
- **Dependencies** (what this service needs) - discoverable from NixOS module imports
- **Instance count** - defined in data-flake
- **Host assignment** - defined in data-flake

### Observability

- **Metrics exporters** - defined in `manifest.observability.metrics`
- **Alerts** - defined in `manifest.observability.alerts`
- **Logs** - defined in `manifest.observability.logging`
- **Probes** - defined in `manifest.observability.probes`

## Rationale

All manifest data and auto-discoverable metadata will be rendered via separate
pipelines (e.g., auto-generated infocards, service topology graphs, dependency
charts). Duplicating this information in README.md creates:

1. **Maintenance burden** - two sources of truth that can drift
2. **Inconsistency** - manual docs may contradict auto-discovered facts
3. **Redundancy** - readers see the same information twice

## Example Structure

```markdown
# Service Name

Brief one-line description.

## Overview

1-2 paragraphs explaining what this service does and why it exists in the
homelab.

Access: `https://service.srv.<publicDomain>`

## Documentation

- [Official Docs](https://upstream-project.io/docs)
- [API Reference](https://upstream-project.io/api)

## Quick Start

\```bash
# Minimal usage example
curl https://service.srv.<publicDomain>/api/endpoint
\```

## Implementation Notes

- Storage: `/var/lib/service`
- Database: PostgreSQL (via db service)
- Homelab-specific quirks or architectural decisions
```

## Integration with Manifest

Service documentation lives alongside the service implementation:

```
services/myservice/
├── manifest.nix          # Structured metadata
├── README.md             # Human-readable docs
├── service.nix           # Implementation
└── docs/                 # Optional: additional doc pages
```

The manifest references the docs:

```nix
serviceName: {
  module = ./service.nix;
  documentation = ./README.md;
  endpoints.web = { port = 8080; protocol = "https"; };
  # ...
}
```

The mdbook pipeline will read `documentation` from all services and builds a
combined documentation site. A separate pipeline will render manifest data into
auto-generated infocards or service detail pages.
