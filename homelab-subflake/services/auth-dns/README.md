# Authoritative DNS (auth_dns)

NSD-based authoritative DNS server for homelab zones.

## Overview

The `auth_dns` service provides authoritative DNS for homelab-specific zones
using NSD (Name Server Daemon). All DNS zones and records are **auto-generated**
from:

- **Service manifests** (via manifest discovery)
- **Host configuration** (network interfaces, IP addresses)
- **Network topology** (subnets, reverse zones)

This service is deployed as multiple instances for high availability. Instances
are independent, there is no zone transfer.

### Architecture

**DNS Query Flow:**

```
Client (192.168.1.x)
  ↓ port 53
Unbound (recursive DNS)
  ↓ localhost:5454 (stub-zone forwarding)
NSD (authoritative DNS on auth-dns-1/auth-dns-2)
  ↓ returns zone data
Unbound → Client
```

- **NSD listens on `127.0.0.1:5454`**
- **Unbound** (from the `dns` service) listens on network interfaces (LAN, backbone, etc.) on port 53
- **Unbound forwards** authoritative zone queries to NSD via `stub-zone` configuration pointing to `127.0.0.1@5454`

## Zones

### `srv.<publicDomain>` - Public Services Zone

Contains DNS records for all homelab services.

**Auto-generated from service manifests:**

- **A/CNAME records**: Point to SSL proxy (for HTTPS services) or direct IPs (for other services)
- **`TXT` location records**: `_i.<service> IN TXT "host=<hostname>"` for service host tracking

**Generation:** `functional/srv-zone-from-manifests.nix`

**Example records:**
```
gitea.srv.<publicDomain>      IN CNAME fluorine.home.arpa.
_i.gitea.srv.<publicDomain>   IN TXT   @ lithium

ntp.srv.<publicDomain>        IN A     192.168.1.1
_i.ntp.srv.<publicDomain>     IN TXT   @ hydrogen
```

### `backbone-inner.<publicDomain>` - Service Interconnect Network

Contains A records for all hosts with backbone-inner network interfaces (`10.200.0.0/24`).

**Auto-generated from:** Host configuration with backbone-inner network interfaces

**Generation:** `functional/backbone-inner.nix`

**Example records:**
```
hydrogen.backbone-inner.<publicDomain>  IN A  10.200.0.1
lithium.backbone-inner.<publicDomain>   IN A  10.200.0.3
```

### `home.arpa` - LAN Zone

Residential LAN devices (RFC 8375).

**Auto-generated from:** DHCP/static LAN assignments

**Example records:**

```
hydrogen.home.arpa  IN A  192.168.1.1
nas.home.arpa       IN A  192.168.1.122
```

### Reverse Zones

Auto-generated PTR records for all forward zones.

**Auto-generated from:** Network topology

**Generation:** `service/reverse.nix`

### Legacy Zones

These zones are being phased out:

- `mgmt.<publicDomain>` - Management network (folding into backbone-inner)
- `db.<publicDomain>` - Database network (folding into backbone-inner)

### TODO

2. **Serial number automation**: Consider auto-incrementing serial on config change.

## Development

### Testing Zone Generation

Build a host with `auth_dns` to see generated zones:

```bash
nix build .#nixosConfigurations.<hostname>.config.services.nsd.zones --json | jq
```

### Updating Zone Serial

```bash
./increment-serial
```

## Related Documentation

- [DNS Architecture](/homelab-subflake/docs/architecture/DNS.md) - Overall DNS infrastructure
- [Service Manifest Format](/homelab-subflake/docs/architecture/MANIFEST-NIX.md) - Service manifest specification
