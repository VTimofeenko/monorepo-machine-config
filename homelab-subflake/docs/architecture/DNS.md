# DNS Architecture

## Overview

The homelab DNS infrastructure consists of two layers:

1. **Recursive DNS (Unbound)**: `dns-1`, `dns-2` - what clients query
2. **Authoritative DNS (NSD)**: `auth-dns-1`, `auth-dns-2` - authoritative for
   homelab zones

Both layers are multi-instance for high availability. All DNS zones and records
are auto-generated from service manifests and data-flake configuration.

## Recursive DNS Layer (Unbound)

### Purpose

Recursive resolvers that clients use for all DNS queries. They:
- Resolve external domains via upstream resolvers
- Forward homelab zones to authoritative DNS
- Block ads and malicious domains
- Resolve LAN hosts as `<hostname>.home.arpa`

### Features

#### Ad and Malware Blocking
Blocks queries to ad and malware domains using blocklists:
- stevenblack blocklist (from nixpkgs)
- Additional custom blocklists
- Per-client block bypass (for clients that shouldn't be blocked)

#### LAN Host Resolution
Resolves LAN devices as `<hostname>.home.arpa`:
- Auto-generated from DHCP leases or static configuration
- Standard RFC 8375 `.home.arpa` domain for residential networks

#### Homelab Zone Forwarding
Forwards queries for homelab zones to authoritative DNS:
- `srv.<publicDomain>` → forward to auth-dns
- `metrics.<publicDomain>` → forward to auth-dns
- Reverse zones for backbone networks → forward to auth-dns

#### External DNS Prevention
Intercepts and redirects queries attempting to use external DNS:
- Firewall rules block outbound port 53 except to local DNS
- Does not prevent DoT with certificate pinning

## Authoritative DNS Layer (NSD)

### Purpose

Authoritative name servers for homelab-specific zones. All records are
**auto-generated** from:
- Service manifests (via manifest discovery)
- Data-flake configuration (host IPs, service assignments)
- Network topology

### Zones

#### Public Services Zone: `srv.<publicDomain>`

Contains records for all homelab services.

**Auto-generated from service manifests:**

```
# Service with HTTPS endpoint
gitea.srv.<publicDomain>     IN A    <ssl-proxy-ip>

# Multi-instance services
dns-1.srv.<publicDomain>     IN A    <host-a-lan-ip>
dns-2.srv.<publicDomain>     IN A    <host-b-lan-ip>

# Service location TXT records
_i.gitea.srv.<publicDomain>  IN TXT  "host=server-1"
```

**Generation logic:**
```
FOR EACH service in serviceManifests:
  FOR EACH instance in (multiInstance ? instances : [serviceName]):

    # Determine which IP to use
    IF service has HTTPS endpoint THEN
      ip = ssl-proxy-ip  # SSL proxy terminates HTTPS
    ELSE
      ip = lib.homelab.getServiceIP instance  # Direct to service
    ENDIF

    # Create A record
    ${instance}.srv.<publicDomain>  IN A  ${ip}

    # Create location TXT record
    _i.${instance}.srv.<publicDomain>  IN TXT  "host=${onHost}"

  ENDFOR
ENDFOR
```

#### Metrics Zone: `metrics.<publicDomain>`

Contains records for metrics endpoints (all point to SSL proxy).

**Explicit records**:
```
FOR EACH service WITH observability.metrics:
  FOR EACH instance:
    ${instance}.metrics.<publicDomain>  IN A  <ssl-proxy-ip>
  ENDFOR
ENDFOR
```

#### Inner Backbone Zone: `backbone-inner.<publicDomain>`

The service interconnect network (`10.200.0.0/24`). Used for all internal service communication (e.g., SSL Proxy -> Service).

**Auto-generated from host configuration:**
```
FOR EACH host WITH backbone-inner interface:
  ${hostname}.backbone-inner.<publicDomain>  IN A  ${backbone-inner-ip}
ENDFOR
```

Example:
```
hydrogen.backbone-inner.<publicDomain>   IN A  10.200.0.1
lithium.backbone-inner.<publicDomain>    IN A  10.200.0.2
```

#### Management Network Zone: `mgmt.<publicDomain>` (Legacy)

Used for out-of-band access. This zone is being folded into `backbone-inner.<publicDomain>`.

#### Database Network Zone: `db.<publicDomain>` (Legacy)

Database network segment. This zone is being folded into `backbone-inner.<publicDomain>`.

#### LAN Zone: `home.arpa`

Residential LAN devices (RFC 8375).

**Auto-generated from DHCP/static assignments:**
```
FOR EACH lan-device:
  ${hostname}.home.arpa  IN A  ${lan-ip}
ENDFOR
```

#### Reverse Zones

Auto-generated PTR records for all forward zones:
- `1.168.192.in-addr.arpa` (LAN)
- `0.200.10.in-addr.arpa` (backbone-inner)
- Additional reverse zones per network segment

## DNS Query Flow

### Client Query: `gitea.srv.<publicDomain>`

```
1. Client → dns-1 (recursive)
2. dns-1 sees query for srv.<publicDomain>
3. dns-1 forwards to auth-dns-1 (authoritative)
4. auth-dns-1 responds: gitea.srv.<publicDomain> IN A <ssl-proxy-ip>
5. dns-1 caches and returns to client
6. Client connects to gitea via SSL proxy
```

### Prometheus Query: `dns-1.metrics.<publicDomain>`

```
1. Prometheus → dns-1 (recursive)
2. dns-1 sees query for metrics.<publicDomain>
3. dns-1 forwards to auth-dns-1 (authoritative)
4. auth-dns-1 responds: *.metrics.<publicDomain> IN A <ssl-proxy-ip>
   OR: dns-1.metrics.<publicDomain> IN A <ssl-proxy-ip>
5. dns-1 caches and returns to Prometheus
6. Prometheus scrapes https://dns-1.metrics.<publicDomain>/metrics
7. SSL proxy receives request, proxies to dns-1's exporter (10.200.0.1:9167)
```

### Client Query: Blocked Domain

```
1. Client → dns-1 (recursive)
2. dns-1 checks blocklist
3. Domain is blocked
4. dns-1 responds: or 0.0.0.0
5. Client connection fails
```

### Client Query: External Domain

```
1. Client → dns-1 (recursive)
2. dns-1 sees query for example.com (not homelab zone)
3. dns-1 queries upstream resolvers recursively
4. dns-1 caches and returns to client
```

## Zone Generation

Zones are auto-generated during NixOS build via manifest discovery.

### Generation Flow

```
1. Manifest Discovery
   ├─ homelab-subflake serviceModules
   └─ data-flake serviceModules

2. For Each Zone:
   ├─ Collect relevant services/hosts
   ├─ Generate zone records
   └─ Write zone file

3. NSD Configuration
   └─ Include generated zone files
```

### Zone File Location

```
/var/lib/nsd/zones/
├─ srv.<publicDomain>.zone
├─ metrics.<publicDomain>.zone
├─ backbone.<publicDomain>.zone
├─ mgmt.<publicDomain>.zone
├─ db.<publicDomain>.zone
├─ home.arpa.zone
└─ reverse/
   ├─ 1.168.192.in-addr.arpa.zone
   ├─ ...
   └─ 0.200.10.in-addr.arpa.zone
```

## Service Examples

### Web Service DNS Records

```nix
# services/gitea/manifest.nix
serviceName: {
  endpoints.web = { port = 3000; protocol = "https"; };
  observability.metrics = { impl = ./metrics.nix; };
  dashboard = { category = "Dev"; links = [{ name = "Gitea"; }]; };
}
```

**Generated DNS records:**
```
# Public services zone
gitea.srv.<publicDomain>      IN A    <ssl-proxy-ip>
_i.gitea.srv.<publicDomain>   IN TXT  "host=server-1"

# Metrics zone (via wildcard)
gitea.metrics.<publicDomain>  → *.metrics.<publicDomain> → <ssl-proxy-ip>
```

### Non-Web Service DNS Records

```nix
# services/ntp/manifest.nix
serviceName: {
  endpoints = {
    ntp = { port = 123; protocol = "udp"; };
    metrics = { port = 9975; protocol = "tcp"; };
  };
  observability.metrics = { impl = ./metrics.nix; };
}
```

**Generated DNS records:**
```
# Public services zone
ntp.srv.<publicDomain>      IN A    <host-ip-in-lan>
_i.ntp.srv.<publicDomain>   IN TXT  "host=hydrogen"

# Metrics zone (via wildcard)
ntp.metrics.<publicDomain>  → *.metrics.<publicDomain> → <ssl-proxy-ip>
```

### Multi-Instance Service DNS Records

```nix
# services/dns/manifest.nix
serviceName: {
  multiInstance = true;
  endpoints = {
    dns = { port = 53; protocol = "udp"; };
    metrics = { port = 9167; protocol = "tcp"; };
  };
  observability.metrics = { impl = ./metrics.nix; };
}
```

**Data-flake instances:**
```nickel
dns-1 = { onHost = "host-a", ... },
dns-2 = { onHost = "host-b", ... },
```

**Generated DNS records:**
```
# Public services zone
dns-1.srv.<publicDomain>      IN A    192.168.1.1   # hydrogen LAN IP
dns-2.srv.<publicDomain>      IN A    192.168.1.2   # lithium LAN IP
_i.dns-1.srv.<publicDomain>   IN TXT  "host=hydrogen"
_i.dns-2.srv.<publicDomain>   IN TXT  "host=lithium"

# Metrics zone (via wildcard)
dns-1.metrics.<publicDomain>  → *.metrics.<publicDomain> → <ssl-proxy-ip>
dns-2.metrics.<publicDomain>  → *.metrics.<publicDomain> → <ssl-proxy-ip>
```

### Logging

**DNStap to analytical DB:**
- All queries logged for analytics
- Query source, query type, response time, blocked status

## Related Documentation

- [MANIFEST-NIX.md](MANIFEST-NIX.md): Service manifest format
- [METRICS.md](METRICS.md): Metrics architecture (including DNS metrics)
