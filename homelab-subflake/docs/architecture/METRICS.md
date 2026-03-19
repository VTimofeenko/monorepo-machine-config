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

  observability.metrics.main = {
    impl = ./metrics.nix;
    endpoint = "web";
    path = "/metrics";
  };
}
```

**SSL proxy behavior:**
- Creates vhost: `gitea.metrics.<publicDomain>`
- Routes `/metrics/main` to service's web endpoint: `http://innerIP:3000/metrics`

**Prometheus scrapes:**
```
https://gitea.metrics.<publicDomain>/metrics/main
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

  observability.metrics.main = {
    impl = ./metrics.nix;
    endpoint = "exporter";
  };
}
```

**SSL proxy behavior:**
- Creates vhost: `nextcloud.metrics.<publicDomain>`
- Routes `/metrics/main` to exporter port: `http://innerIP:9205/metrics`

**Prometheus scrapes:**
```
https://nextcloud.metrics.<publicDomain>/metrics/main
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

  observability.metrics.main = {
    impl = ./metrics.nix;
    endpoint = "metrics";
  };
}
```

**SSL proxy behavior:**
- Creates vhost: `ntp.metrics.<publicDomain>`
- Routes `/metrics/main` to exporter: `http://innerIP:9975/metrics`

**Prometheus scrapes:**
```
https://ntp.metrics.<publicDomain>/metrics/main
```

## SSL Proxy Auto-Generation

For each service with `observability.metrics`, SSL proxy generates a metrics vhost with path-based routing:

```
FOR EACH service WITH observability.metrics:
  FOR EACH instance IN (multiInstance ? data-flake.getInstances(service) : [serviceName]):

    # Generate single vhost for this instance
    server {
      server_name ${instance}.metrics.<publicDomain>;

      # Generate location per exporter
      FOR EACH (exporterName, exporterConfig) IN observability.metrics:

        # Determine which endpoint exposes metrics
        metricsEndpoint = IF exporterConfig.endpoint specified THEN
                            endpoints[exporterConfig.endpoint]
                          ELSE IF endpoints.metrics exists THEN
                            endpoints.metrics
                          ELSE
                            first HTTPS endpoint

        location /metrics/${exporterName} {
          proxy_pass http://${innerIP}:${metricsEndpoint.port}${exporterConfig.path};

          # Access control: only Prometheus
          allow ${prometheusIP};
          deny all;
        }
      ENDFOR
    }
  ENDFOR
ENDFOR
```

**Key points:**
- One vhost per service instance
- Path-based routing: `/metrics/<exporterName>` (always named, even for single exporters)
- All vhosts follow `<instance>.metrics.<publicDomain>` pattern
- Single exporters typically use `main` as the exporter name
- Routing target determined by endpoint inference
- Access control enforced at SSL proxy

**Example: Single exporter**
```nginx
server {
  server_name gitea.metrics.<publicDomain>;

  location /metrics/main {
    proxy_pass http://10.0.0.5:3000/metrics;
    allow 10.0.0.10;  # Prometheus
    deny all;
  }
}
```

**Example: Multiple exporters**
```nginx
server {
  server_name <serviceName>.metrics.<publicDomain>;

  location /metrics/app {
    proxy_pass http://10.0.0.5:9001/metrics;
    allow 10.0.0.10;  # Prometheus
    deny all;
  }

  location /metrics/geo {
    proxy_pass http://10.0.0.5:9002/metrics;
    allow 10.0.0.10;  # Prometheus
    deny all;
  }
}
```

## Prometheus Scraping

Prometheus configuration generates separate scrape jobs per exporter:

```nix
# prometheus/service-scraping/gather-services-from-manifests.nix
serviceManifests
  |> lib.filterAttrs (_: m: m.observability.metrics != {})
  |> lib.mapAttrsToList (srvName: manifest:
    let
      # Expand instances if multiInstance
      instances = if manifest.multiInstance or false then
        data-flake.getInstancesForService srvName
      else
        [srvName];
    in
    # Generate scrape config per instance per exporter
    lib.flatten (map (instanceName:
      lib.mapAttrsToList (exporterName: exporterConfig:
        {
          job_name = "${instanceName}-${exporterName}-metrics";
          scheme = "https";
          metrics_path = "/metrics/${exporterName}";
          static_configs = [{
            targets = ["${instanceName}.metrics.<publicDomain>"];
            labels = {
              service = srvName;
              instance = instanceName;
              exporter = exporterName;
            };
          }];
        }
      ) manifest.observability.metrics
    ) instances)
  )
```

**Generated config examples:**

```yaml
# Single-instance, single exporter
- job_name: gitea-main-metrics
  scheme: https
  metrics_path: /metrics/main
  static_configs:
    - targets: [gitea.metrics.<publicDomain>]
      labels:
        service: gitea
        instance: gitea
        exporter: main

# Single-instance, multiple exporters
- job_name: <serviceName>-app-metrics
  scheme: https
  metrics_path: /metrics/app
  static_configs:
    - targets: [<serviceName>.metrics.<publicDomain>]
      labels:
        service: <serviceName>
        instance: <serviceName>
        exporter: app

- job_name: <serviceName>-geo-metrics
  scheme: https
  metrics_path: /metrics/geo
  static_configs:
    - targets: [<serviceName>.metrics.<publicDomain>]
      labels:
        service: <serviceName>
        instance: <serviceName>
        exporter: geo

# Multi-instance service
- job_name: dns-1-main-metrics
  scheme: https
  metrics_path: /metrics/main
  static_configs:
    - targets: [dns-1.metrics.<publicDomain>]
      labels:
        service: dns
        instance: dns-1
        exporter: main

- job_name: dns-2-main-metrics
  scheme: https
  metrics_path: /metrics/main
  static_configs:
    - targets: [dns-2.metrics.<publicDomain>]
      labels:
        service: dns
        instance: dns-2
        exporter: main
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

  observability.metrics.main = {
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
  location /metrics/main {
    proxy_pass http://10.200.0.1:9167/metrics;  # host-a inner IP
  }
}

server {
  server_name dns-2.metrics.<publicDomain>;
  location /metrics/main {
    proxy_pass http://10.200.0.2:9167/metrics;  # host-b inner IP
  }
}
```

**Prometheus scrapes both:**

```yaml
- job_name: dns-1-main-metrics
  scheme: https
  metrics_path: /metrics/main
  static_configs:
    - targets: [dns-1.metrics.<publicDomain>]
      labels:
        service: dns
        instance: dns-1
        exporter: main

- job_name: dns-2-main-metrics
  scheme: https
  metrics_path: /metrics/main
  static_configs:
    - targets: [dns-2.metrics.<publicDomain>]
      labels:
        service: dns
        instance: dns-2
        exporter: main
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

  # Metrics configuration (supports multiple exporters)
  observability.metrics = {
    <exporterName> = {
      impl = Path;              # Required: metrics module
      endpoint = String;        # Optional: which endpoint (inferred if omitted)
      path = String;            # Optional: metrics path (default: "/metrics")
    };
  };
}
```

**Multiple exporters:**

Services can declare multiple metrics exporters (e.g., app-specific + infrastructure):

```nix
serviceName: "<serviceName>"
{
  endpoints = {
    web = { port = 8096; protocol = "https"; };
    app-exporter = { port = 9001; protocol = "tcp"; };
    geo-exporter = { port = 9002; protocol = "tcp"; };
  };

  observability.metrics = {
    app = {
      impl = ./app-metrics.nix;
      endpoint = "app-exporter";
    };
    geo = {
      impl = ./geo-metrics.nix;
      endpoint = "geo-exporter";
    };
  };
}
```

Each exporter is exposed at:
- `https://<serviceName>.metrics.<publicDomain>/metrics/app`
- `https://<serviceName>.metrics.<publicDomain>/metrics/geo`

**Naming convention:**
- Single exporter: Use `main` (e.g., `metrics.main = { ... }`)
- Multiple exporters: Use descriptive names (`app`, `geo`, `infra`, etc.)
- **Migration-friendly:** Adding a second exporter doesn't break the first one's scrape config

**Endpoint inference:** If `endpoint` not specified:

1. If endpoint named `"metrics"` exists: use it
2. Else: use first `https` endpoint

## Complete Examples

### Single Exporter: Gitea (Web, metrics on main endpoint)

```nix
serviceName: {
  module = ./gitea.nix;

  endpoints.web = { port = 3000; protocol = "https"; };

  observability.metrics.main = {
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
- Metrics: `https://gitea.metrics.<publicDomain>/metrics/main` → routes to port 3000

### Single Exporter: PostgreSQL (Separate exporter)

```nix
serviceName: {
  module = ./postgresql.nix;

  endpoints = {
    postgres = { port = 5432; protocol = "tcp"; };
    exporter = { port = 9187; protocol = "tcp"; };
  };

  observability.metrics.main = {
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
- Metrics: `https://db.metrics.<publicDomain>/metrics/main` → routes to port 9187

### Multiple Exporters: <serviceName> (App + Geo metrics)

```nix
serviceName: {
  module = ./<serviceName>.nix;

  endpoints = {
    web = { port = 8096; protocol = "https"; };
    app-exporter = { port = 9001; protocol = "tcp"; };
    geo-exporter = { port = 9002; protocol = "tcp"; };
  };

  observability.metrics = {
    app = {
      impl = ./app-metrics.nix;
      endpoint = "app-exporter";
    };
    geo = {
      impl = ./geo-metrics.nix;
      endpoint = "geo-exporter";
    };
  };

  dashboard = {
    category = "Media";
    links = [{ name = "<serviceName>"; }];
  };
}
```

**Result:**

- Service: `https://<serviceName>.<publicDomain>`
- Metrics:
  - `https://<serviceName>.metrics.<publicDomain>/metrics/app` → routes to port 9001
  - `https://<serviceName>.metrics.<publicDomain>/metrics/geo` → routes to port 9002

All services use the same metrics pattern with path-based routing.
