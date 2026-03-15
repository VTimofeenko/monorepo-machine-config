# Metrics Architecture

## Overview

All Prometheus metrics scraping uses a unified pattern: every service's metrics
are exposed at `<service>.metrics.<publicDomain>/metrics`. All requests go
through the SSL proxy via HTTPS, which routes to the actual exporters.

**Benefits:**
- Single, consistent pattern for all services
- Clear separation: metrics zone distinct from service zone
- Multi-instance friendly: `dns-1.metrics` vs `dns-2.metrics`
- Explicit, per-instance DNS records for maximum clarity
- Centralized access control and HA via SSL proxy

## The Unified Pattern

**Every service with metrics:**
```
https://<instance>.metrics.<publicDomain>/metrics
```

**Examples:**
- `https://gitea.metrics.<publicDomain>/metrics`
- `https://nextcloud.metrics.<publicDomain>/metrics`
- `https://ntp.metrics.<publicDomain>/metrics`
- `https://dns-1.metrics.<publicDomain>/metrics`
- `https://dns-2.metrics.<publicDomain>/metrics`

## Service Types

While the access pattern is uniform, services expose metrics in different ways:

### Web Service - Metrics on Main Endpoint

Service exposes metrics on its HTTPS endpoint.

**Example: Gitea**

```nix
serviceName: {
  module = ./gitea.nix;

  endpoints.web = { port = 3000; protocol = "https"; };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "web";
    path = "/metrics";
  };
}
```

**SSL proxy behavior:**
- Creates vhost: `gitea.metrics.<publicDomain>`
- Routes `/metrics` to service's web endpoint: `http://innerIP:3000/metrics`

**Prometheus scrapes:**
```
https://gitea.metrics.<publicDomain>/metrics
```

### Web Service - Separate Exporter

Service has an HTTPS endpoint for users, plus a separate exporter on different port.

**Example: Nextcloud**
```nix
serviceName: {
  module = ./nextcloud.nix;

  endpoints = {
    web = { port = 80; protocol = "https"; };
    exporter = { port = 9205; protocol = "tcp"; };
  };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "exporter";
  };
}
```

**SSL proxy behavior:**
- Creates vhost: `nextcloud.metrics.<publicDomain>`
- Routes `/metrics` to exporter port: `http://innerIP:9205/metrics`

**Prometheus scrapes:**
```
https://nextcloud.metrics.<publicDomain>/metrics
```

### Non-Web Service (UDP/TCP)

Service runs over UDP/TCP (no HTTPS), with separate metrics exporter.

**Example: NTP**
```nix
serviceName: {
  module = ./ntp.nix;

  endpoints = {
    ntp = { port = 123; protocol = "udp"; };
    metrics = { port = 9975; protocol = "tcp"; };
  };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "metrics";
  };
}
```

**SSL proxy behavior:**
- Creates vhost: `ntp.metrics.<publicDomain>`
- Routes `/metrics` to exporter: `http://innerIP:9975/metrics`

**Prometheus scrapes:**
```
https://ntp.metrics.<publicDomain>/metrics
```

## SSL Proxy Auto-Generation

For each service with `observability.metrics`, SSL proxy generates a metrics vhost:

```
FOR EACH service WITH observability.metrics:
  FOR EACH instance IN (multiInstance ? data-flake.getInstances(service) : [serviceName]):

    # Determine which endpoint exposes metrics
    metricsEndpoint = IF metrics.endpoint specified THEN
                        endpoints[metrics.endpoint]
                      ELSE IF endpoints.metrics exists THEN
                        endpoints.metrics
                      ELSE
                        first HTTPS endpoint

    # Generate vhost
    server {
      server_name ${instance}.metrics.<publicDomain>;

      location /metrics {
        proxy_pass http://${innerIP}:${metricsEndpoint.port}${metricsPath};

        # Access control: only Prometheus
        allow ${prometheusIP};
        deny all;
      }
    }
  ENDFOR
ENDFOR
```

**Key points:**
- One vhost per service instance
- All vhosts follow `<instance>.metrics.<publicDomain>` pattern
- Routing target determined by endpoint inference
- Access control enforced at SSL proxy

## Prometheus Scraping

Prometheus configuration is uniform - always HTTPS to the metrics zone:

```nix
# prometheus/service-scraping/gather-services-from-manifests.nix
serviceManifests
  |> lib.filterAttrs (_: m: m ? observability.metrics)
  |> lib.mapAttrsToList (srvName: manifest:
    let
      metrics = manifest.observability.metrics;
      metricsPath = metrics.path or "/metrics";

      # Expand instances if multiInstance
      instances = if manifest.multiInstance or false then
        data-flake.getInstancesForService srvName
      else
        [srvName];
    in
    # Generate scrape config for each instance
    map (instanceName: {
      job_name = "${instanceName}-srv-scrape";
      scheme = "https";
      metrics_path = metricsPath;
      targets = ["${instanceName}.metrics.<publicDomain>"];
    }) instances
  )
```

**Generated config examples:**

```yaml
# Single-instance service
- job_name: gitea-srv-scrape
  scheme: https
  metrics_path: /metrics
  targets:
    - gitea.metrics.<publicDomain>

# Multi-instance service
- job_name: dns-1-srv-scrape
  scheme: https
  metrics_path: /metrics
  targets:
    - dns-1.metrics.<publicDomain>

- job_name: dns-2-srv-scrape
  scheme: https
  metrics_path: /metrics
  targets:
    - dns-2.metrics.<publicDomain>
```

## DNS Configuration

Every metrics endpoint requires an explicit A record pointing to the SSL proxy. **Wildcard DNS is not used** to ensure only legitimate metrics endpoints are resolvable.

- `gitea.metrics.<publicDomain>` → SSL proxy
- `ntp.metrics.<publicDomain>` → SSL proxy
- `dns-1.metrics.<publicDomain>` → SSL proxy
- `dns-2.metrics.<publicDomain>` → SSL proxy

**Zone generation:** The auth_dns service auto-generates these records from the
services inventory in data-flake.

## Multi-Instance Services

Multi-instance services like DNS get separate metrics vhosts per instance:

**Manifest (services/dns/manifest.nix):**
```nix
serviceName: {
  module = ./unbound.nix;
  multiInstance = true;

  endpoints = {
    dns = { port = 53; protocol = "udp"; };
    metrics = { port = 9167; protocol = "tcp"; };
  };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "metrics";
  };
}
```

**Data-flake entries:**
```nickel
dns-1 = {
  onHost = "host-a",
  settings = { ... },
},

dns-2 = std.record.update "onHost" "host-b" dns-1,
```

**SSL proxy generates:**
```nginx
server {
  server_name dns-1.metrics.<publicDomain>;
  location /metrics {
    proxy_pass http://10.200.0.1:9167/metrics;  # host-a inner IP
  }
}

server {
  server_name dns-2.metrics.<publicDomain>;
  location /metrics {
    proxy_pass http://10.200.0.2:9167/metrics;  # host-b inner IP
  }
}
```

**Prometheus scrapes both:**

```yaml
- job_name: dns-1-srv-scrape
  scheme: https
  metrics_path: /metrics
  targets: [dns-1.metrics.<publicDomain>]

- job_name: dns-2-srv-scrape
  scheme: https
  metrics_path: /metrics
  targets: [dns-2.metrics.<publicDomain>]
```

## Access Control

SSL proxy enforces that only Prometheus can access metrics endpoints.

**Implementation options:**

### IP Allowlist

```nginx
location /metrics {
  allow 10.200.0.5;  # Prometheus host
  deny all;
  proxy_pass http://...;
}
```

### Bearer Token

```nix
# Manifest
observability.metrics = {
  impl = ./metrics.nix;
};
```

```nginx
# SSL proxy checks Authorization header
location /metrics {
  if ($http_authorization != "Bearer secret-token") {
    return 403;
  }
  proxy_pass http://...;
}
```

```yaml
# Prometheus config
- job_name: service-scrape
  bearer_token: secret-token
  targets: [...]
```

### mTLS

Client certificate authentication (future enhancement).

## High Availability

SSL proxy can be multi-instance for HA:

**Deployment:**

- SSL proxy on host-a (primary)
- SSL proxy on host-b (secondary)

**DNS:**
```
*.metrics.<publicDomain>  IN A  <host-a-ip>
*.metrics.<publicDomain>  IN A  <host-b-ip>
```

Round-robin DNS provides basic HA. If host-a fails, Prometheus resolves to host-b.

## Manifest Declaration

See [MANIFEST-NIX.md](MANIFEST-NIX.md) for full schema. Metrics-relevant fields:

```nix
serviceName: {
  # Define service endpoints
  endpoints = {
    <name> = {
      port = Int;
      protocol = "tcp" | "udp" | "https";
    };
  };

  # Metrics configuration
  observability.metrics = {
    impl = Path;              # Required: metrics module
    endpoint = String;        # Optional: which endpoint (inferred if omitted)
    path = String;            # Optional: metrics path (default: "/metrics")
  };
}
```

**Endpoint inference:** If `endpoint` not specified:

1. If endpoint named `"metrics"` exists: use it
2. Else: use first `https` endpoint

## Complete Example: Three Service Types

### Gitea (Web, metrics on main endpoint)

```nix
serviceName: {
  module = ./gitea.nix;

  endpoints.web = { port = 3000; protocol = "https"; };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "web";
  };

  dashboard = {
    category = "Dev";
    links = [{ name = "Gitea"; }];
  };
}
```

**Result:**

- Service: `https://gitea.<publicDomain>`
- Metrics: `https://gitea.metrics.<publicDomain>/metrics` → routes to port 3000

### PostgreSQL (Web, separate exporter)

```nix
serviceName: {
  module = ./postgresql.nix;

  endpoints = {
    postgres = { port = 5432; protocol = "tcp"; };
    exporter = { port = 9187; protocol = "tcp"; };
  };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "exporter";
  };

  backups.impl = { lib, ... }: lib.localLib.mkBkp {
    inherit serviceName;
    localDB = true;
  };

  storage.impl = ./storage.nix;
}
```

**Result:**

- Service: `postgres://db.<publicDomain>:5432` (no HTTPS)
- Metrics: `https://db.metrics.<publicDomain>/metrics` → routes to port 9187

### NTP (UDP, separate exporter)

```nix
serviceName: {
  module = ./ntp.nix;

  endpoints = {
    ntp = { port = 123; protocol = "udp"; };
    metrics = { port = 9975; protocol = "tcp"; };
  };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "metrics";
  };
}
```

**Result:**

- Service: `ntp://ntp.<publicDomain>:123` (UDP)
- Metrics: `https://ntp.metrics.<publicDomain>/metrics` → routes to port 9975

All three use the same metrics pattern, regardless of service type.
