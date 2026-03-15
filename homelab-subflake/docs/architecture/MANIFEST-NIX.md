# manifest.nix Format

## Overview

`manifest.nix` is a data structure describing a service's implementation and metadata. It has two jobs:

1. **Construct NixOS configuration** for the host where the service runs
2. **Expose metadata** for other services to consume (SSL config, metrics endpoints, dashboard links, etc.)

Manifests are functions that take `serviceName` as an argument and return an
attrset. The `default` attribute is auto-assembled from other fields,
eliminating manual module list maintenance.

## Function Signature

```nix
# homelab-subflake/services/myservice/manifest.nix
serviceName: {
  # ... manifest fields
}
```

The `serviceName` argument is extracted from the service directory path by the
homelab flake's discovery mechanism. It may be consumed as a top-level argument
by the implementation module.

## Schema

```nix
serviceName: {
  # Core service module (optional)
  # Can be omitted for stub services (services existing only for side-effects)
  # When data-flake declares moduleName = "stub", this field is ignored.
  module? : Path

  # Multi-instance flag (optional, default: false)
  # Signals to consumers: "Look up my instances in data-flake"
  # Used by services deployed multiple times (e.g., dns_1, dns_2)
  multiInstance? : Bool

  # Service endpoints (optional - omit if no network endpoints)
  endpoints? :: {
    <name> : {
      port : Int
      protocol : "tcp" | "udp" | "https"
      path? : String              # For https, default: "/"
      extraConfig? : String       # nginx extraConfig (for SSL tweaks)
    }

    # Optional: Module to configure service to use these ports
    # Receives all endpoints (except impl) as argument
    impl? : (Endpoints -> Module)
  }

  # Firewall (optional)
  # If present: use this implementation
  # If absent: auto-generate from endpoints (opens ports on backbone-inner)
  firewall? : Path

  # SSL proxy configuration (optional)
  # If present: use this implementation
  # If absent: auto-generate from https endpoints
  sslProxyConfig? : Path

  # Observability (optional)
  observability? :: {
    metrics? :: {
      impl : Path               # Metrics module (presence = metrics enabled)
      endpoint? : String        # Which endpoint? Inferred if omitted
      endpoints? : [String]     # Multiple exporters
      path? : String            # Metrics path, default: "/metrics"
    }

    alerts? :: {
      grafanaImpl : Path        # Alert rules for Grafana
      # FUTURE: alertManagerImpl : Path # Alert rules for alert-manager
    }

    logging? :: {
      impl : Path               # Logging configuration module
    }

    probes? :: {
      impl : Path               # Probe exporter module
      endpoint : String         # Which endpoint to probe
      prometheusImpl : Path     # Prometheus probe configuration
    }
  }

  # Backups (optional)
  backups? ::
    # Standard case: wrapper around lib.localLib.mkBkp
    | { paths : [String]
        exclude? : [String]
        schedule? : String
        localDB? : Bool         # Include database dump
        localOnly? : Bool       # Skip remote backup
      }
    # Custom case: service-specific backup logic
    | { impl : Module }

  # Storage (optional)
  storage? :: {
    impl : Path                 # Storage configuration module
  }

  # Dashboard integration (optional)
  dashboard? :: {
    category : String           # Category name (e.g., "Admin", "Home")
    links : [
      {
        name : String           # Display name
        description? : String   # Description
        icon? : String          # Icon name (from dashboard-icons)
        path? : String          # URL path, default: "/"
        absoluteURL? : String   # Override auto-generated URL
      }
    ]
  }

  # Documentation (optional)
  # Path to README.md in service directory
  # Used by mdbook pipeline to generate service documentation
  documentation? : Path

  # Service-specific utilities that may be called by other services (optional)
  srvLib? : Any
}
```

## Auto-Assembly

The `default` attribute is automatically assembled from manifest fields:

```nix
default = flatten([
  (manifest.module OR []),
  endpoints.impl(endpoints),  # Called with endpoint data
  (manifest.firewall OR auto-generate-firewall(endpoints)),
  observability.metrics.impl,
  observability.logging.impl,
  observability.probes.impl,
  (backups.impl OR auto-generate-mkBkp(backups)),
  storage.impl
]) |> filter(not-null)

# magic `not-null` function filters out nulls and attrs that are not present
```

**Note:** When data-flake declares `moduleName = "stub"` for a service, `mkHost`
skips the assembly of local implementation. Stub services exist only for
side-effects. Other services, however, may still read the manifests.

**Firewall auto-generation**: Opens all endpoint ports on the backbone-inner
network by default.

**SSL proxy auto-generation**: Creates nginx virtual hosts for all `https`
endpoints, including any `extraConfig`.

**Backups auto-generation**: Wraps data in `lib.localLib.mkBkp { inherit
serviceName; ... }`.

## Customization Levels

Manifests support three levels of customization:

### Level 1: Full Auto (80% of services)

Define endpoints and data; everything else is auto-generated.

```nix
serviceName: {
  module = ./service.nix;

  endpoints.web = { port = 3000; protocol = "https"; };

  observability.metrics.impl = ./metrics.nix;

  backups.paths = [ "/var/lib/${serviceName}" ];

  dashboard = {
    category = "Home";
    links = [{ name = "Some service"; icon = "some-service"; }];
  };
}
```

In practice this means that:

1. Service's host will have the following config:

    - `service.nix` containing the service implementation. Service.nix may
      import other files.
    - `./metrics.nix` contains the service's config that enables metrics
    - standard backup implementation of backups, backing up `backups.paths`
      paths

2. SSL proxy will auto-generate a vhost for the service's FQDN and proxying it
   to port 3000 over backbone-inner network.
3. Prometheus will scrape `https://<serviceFQDN>/metrics` for metrics
4. No auto-provisioned alerts
5. Dashboard will have a tile based on the `.dashboard` attribute

### Level 2: Small Tweaks (15% of services)

Use `extraConfig` or provide single override.

```nix
serviceName: {
  module = ./nextcloud.nix;

  endpoints.web = {
    port = 80;
    protocol = "https";
    extraConfig = "client_max_body_size 10G;";  # SSL proxy includes this
  };

  endpoints.metrics = {
    port = 9000;
    protocol = "https";
  };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "metrics";
  };

  backups.paths = [ "/var/lib/nextcloud" ];
  storage.impl = ./storage.nix;
}
```

Or override firewall for non-standard networking:

```nix
serviceName: {
  module = ./kea.nix;

  endpoints = {
    dhcp = { port = 67; protocol = "udp"; };
    metrics = { port = 9547; protocol = "tcp"; };
  };

  firewall = ./firewall.nix;  # Opens DHCP on LAN, metrics on backbone-inner

  observability.metrics.impl = ./metrics.nix;
}
```

### Level 3: Fullly Custom (5% of services)

Provide complete custom implementations.

```nix
serviceName: {
  module = ./keycloak.nix;

  endpoints.web = { port = 8080; protocol = "https"; };

  sslProxyConfig = ./ssl.nix;  # Custom nginx config

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "web";
  };

  backups.impl = { lib, ... }: lib.localLib.mkBkp {
    inherit serviceName;
    localDB = true;
    # Custom backup logic
  };
}
```

## Examples

### Standard Web Service

```nix
serviceName: {
  module = ./actual.nix;

  endpoints.web = { port = 3001; protocol = "https"; };

  observability.metrics.impl = ./metrics.nix;

  backups = {
    paths = [ "/var/lib/actual" ];
    schedule = "daily";
  };

  dashboard = {
    category = "Home";
    links = [{
      name = "Actual Budget";
      description = "Local budgeting";
      icon = "actual-budget";
    }];
  };
}
```

### Multi-Endpoint Service

```nix
serviceName: {
  module = ./gitea.nix;

  endpoints = {
    web = { port = 3000; protocol = "https"; };
    ssh = { port = 22; protocol = "tcp"; };
  };

  observability.metrics = {
    impl = ./metrics.nix;
    endpoint = "web";
  };

  backups.paths = [ "/var/lib/gitea" ];

  dashboard = {
    category = "Dev";
    links = [{ name = "Gitea"; icon = "gitea"; }];
  };
}
```

### TCP Service with Separate Exporter

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

### Service with No Endpoints

```nix
serviceName: {
  module = ./ddns-updater.nix;
  # No endpoints - just systemd timers and side effects
}
```

### Multi-Instance Service (DNS)

```nix
serviceName: {
  module = ./unbound.nix;

  multiInstance = true;  # Signals: dns_1 and dns_2 instances exist

  endpoints = {
    dns = { port = 53; protocol = "udp"; };
    metrics = { port = 9167; protocol = "tcp"; };
  };

  firewall = ./firewall.nix;  # Opens DNS on all networks, not just backbone-inner

  observability.metrics.impl = ./metrics.nix;
}
```

Data-flake contains separate entries for `dns_1` (on host-a) and `dns_2` (on
host-b) with per-instance settings. Consumers expand instances by checking
data-flake through `lib.homelab.get*` interface when they see `multiInstance =
true`.

### Metrics-Only Service

```nix
serviceName: {
  module = ./rsync-net-exporter.nix;

  endpoints.metrics = { port = 9999; protocol = "tcp"; };

  observability.metrics = {
    impl = ./metrics.nix;
    # Scrapes external rsync.net API, exposes metrics locally
  };
}
```

### Stub Service (Side-effects only)

```nix
serviceName: {
  # No local daemon - module omitted
  # data-flake declares moduleName = "stub" for this service

  endpoints.web = {
    port = 443;
    protocol = "https";
    # extraConfig can contain arbitrary nginx directives
    # This example is purely for illustrative purposes. Real example would be a
    # function of `serviceName`
    extraConfig = ''
      proxy_pass https://192.168.x.x;  # Forward to hardware appliance
    '';
  };

  dashboard = {
    category = "Infrastructure";
    links = [{ name = "Ruckus Controller"; icon = "wifi"; }];
  };
}
```

**Stub services** exist only to generate side-effects (SSL proxy vhosts,
dashboard links). They have no local NixOS module. The `moduleName = "stub"`
declaration in data-flake causes mkHost to skip this service during NixOS config
assembly.

## Service Discovery and Consumption

### Manifest Discovery (Homelab Flake)

The homelab flake discovers services and calls manifests:

```nix
let
  serviceName = baseNameOf (toString servicePath);  # "actual" from .../actual
  manifest = import "${servicePath}/manifest.nix" serviceName;
in
manifest
```

### Remote Metadata Consumers

Other services read manifest metadata directly:

**SSL Proxy** (`ssl-proxy/service.nix`):
```nix
serviceManifests
  |> lib.filterAttrs (_: m: hasHttpsEndpoint m.endpoints)
  |> lib.mapAttrsToList (srvName: m:
    if m ? sslProxyConfig then
      import m.sslProxyConfig { inherit srvName; }
    else
      auto-generate-nginx-vhost m.endpoints srvName
  )
```

**Prometheus** (`prometheus/service-scraping/gather-services-from-manifests.nix`):

```nix
serviceManifests
  |> lib.filterAttrs (_: m: m ? observability.metrics)
  |> lib.mapAttrsToList (srvName: manifest:
    let
      metrics = manifest.observability.metrics;
      endpoint = resolveMetricsEndpoint manifest;
      isHttps = endpoint.protocol == "https";

      # Expand instances if multiInstance flag is set
      instances = if manifest.multiInstance or false then
        data-flake.getInstancesForService srvName  # ["dns_1" "dns_2"]
      else
        [srvName];  # ["actual"]
    in
    # Generate scrape config for each instance
    map (instanceName: {
      job_name = "${instanceName}-srv-scrape";
      scheme = "https";
      metrics_path = metrics.path or "/metrics";
      targets = ["${instanceName}.metrics.<publicDomain>"];
    }) instances
  )
```

**Home Dashboard** (`home-dashboard/functional/add-links-from-manifests.nix`):
```nix
serviceManifests
  |> lib.filterAttrs (_: m: m ? dashboard)
  |> lib.mapAttrsToList (srvName: m:
    {
      "${m.dashboard.category}" = m.dashboard.links;
    }
  )
```

## Metrics Architecture

The homelab uses a unified metrics architecture where all Prometheus scraping
goes through the SSL proxy via HTTPS. The SSL proxy auto-detects metrics
exporters from manifests and handles routing.

**Endpoint inference:** When `observability.metrics` exists but no endpoint is
specified:
1. If an endpoint named `"metrics"` exists: use it (separate exporter)
2. Else: use the first `https` endpoint (metrics on main service)

**See [METRICS.md](METRICS.md) for complete architecture details**, including:
- Three metrics patterns (metrics on web endpoint, separate exporter, non-web
  services)
- SSL proxy auto-detection logic
- Prometheus scraping configuration
- DNS requirements for non-web services

## Multi-Instance Services

Services like `dns_1` and `dns_2` share a base manifest at
`services/dns/manifest.nix`. The manifest declares `multiInstance = true` to
signal consumers that multiple instances exist.

**Instance Discovery Flow:**

1. **Manifest declares capability**: `multiInstance = true` in `services/dns/manifest.nix`
2. **Data-flake owns topology**: dns_1 on host-a, dns_2 on host-b (in data-flake service entries)
3. **Consumers expand instances**: When processing the dns manifest, consumers check data-flake for instance names

**Consumer Pattern:**

```nix
# prometheus/service-scraping/gather-services-from-manifests.nix
serviceManifests
  |> lib.mapAttrsToList (srvName: manifest:
    let
      # Expand instances if multiInstance flag is set
      instances = if manifest.multiInstance or false then
        data-flake.getInstancesForService srvName  # ["dns_1" "dns_2"]
      else
        [srvName];  # ["actual"]
    in
    # Generate scrape config for each instance
    map (instanceName: {
      job_name = "${instanceName}-scrape";
      scheme = "https";
      targets = [ "${instanceName}.metrics.<publicDomain>" ];
      # ... use manifest metadata
    }) instances
  )
```

The corresponding extract from `data-flake`:

```nickel
  dns_1 = {
    groups = [ ... ],
    onHost = "host-a",
    networkAccess = [ ... ],
    settings = { ... },
  },

  dns_2 = std.record.update "onHost" "host-b" dns_1,

```

**Benefits:**
- Single source of truth: data-flake owns instance names and deployment topology
- Manifest just declares capability: "I support multiple instances"
- No hardcoded special cases in consumers
- Per-instance differences (settings, host assignments) live in data-flake

## Deprecated fields/concepts

- `acl`: to be merged into firewall/functional impl. Future rework
- `logging.systemdUnit`: unused in practice. May return when automated analytics
  is added.
- `default.nix` file inside the service directory. The `mkHost`-adjacent
  machinery will create this module instead of going back to the service
  directory and read `default.nix` as a shim
