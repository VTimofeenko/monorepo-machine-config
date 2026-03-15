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

- **API endpoints** and how to call them (examples with curl, code snippets)
- **Web UI** navigation and features
- **Configuration options** not obvious from NixOS module options
- **Integration patterns** with other services (when non-standard)

### Implementation Details

- **Architecture decisions** specific to this service
- **Quirks or gotchas** that operators should know
- **Troubleshooting** common issues
- **Migration notes** if service was refactored

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

2-3 paragraphs explaining what this service does, why it exists,
and how it fits into the homelab architecture.

## Usage

### Web Interface

Description of UI features, workflows, etc.

### API

Code examples showing how to interact with the service:

\```bash
curl -X POST https://service.srv.<publicDomain>/api/endpoint \\
  -H "Content-Type: application/json" \\
  -d '{"key": "value"}'
\```

## Configuration

Explain non-obvious NixOS options or configuration patterns.

## Troubleshooting

Common issues and how to resolve them.

## Implementation Notes

Architecture decisions, quirks, or important context for maintainers.
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
