# Host Architecture

## Overview

A **host** is a physical or virtual machine running NixOS in the homelab. Each
host has:

- Hardware configuration
- Service assignments (which services run on this host)
- Trait assignments (which configuration traits apply)

Host metadata lives in **data-flake**, while the **homelab-subflake** consumes
this data to build NixOS configurations.

## Host Definition

Hosts are defined in `data-flake` with metadata:

```nickel
# In data-flake
{
  hosts.all.lithium = {
    system = "aarch64-linux",
    servicesAt = [ "gitea", "cyberchef", "apprise" ],
    traitsAt = [
      "backbone-inner-net",
      "lan-net",
      "sshd",
      # ...
    ],
    # Network interfaces, IPs, SSH keys, etc.
  }
}
```

## Building a Host Configuration

The `mkHost` function in `homelab-subflake/flake-lib.nix` consumes host
metadata and assembles a NixOS configuration:

```nix
# In homelab-subflake/flake.nix
nixosConfigurations.lithium = mkHost {
  hostName = "lithium";
};
```

### `mkHost` Resolution Process

1. **Read host metadata** from `data-flake.data.hosts.all.${hostName}`
2. **Resolve services** from `servicesAt`:
   - Check `self.serviceModules.${moduleName}` (public, in homelab-subflake)
   - Check `inputs.private-modules.serviceModules.${moduleName}` (private)
   - Import service's `default` modules (auto-assembled from manifest)
3. **Resolve traits** from `traitsAt`:
   - Check `self.traitModules.${traitName}` (public)
   - Check `inputs.private-modules.traitModules.${traitName}` (private)
4. **Resolve secrets** from `private-modules.secretModules.${hostName}`
5. **Assemble final configuration** with all modules

### Debug Traces

When building a host configuration, `mkHost` emits traces showing resolution:

```
trace: [mkHost:lithium] system=aarch64-linux
trace: [mkHost:lithium] service apprise (private)
trace: [mkHost:lithium] service cyberchef (public)
trace: [mkHost:lithium] service gitea (public)
trace: [mkHost:lithium] trait backbone-inner-net (private)
trace: [mkHost:lithium] trait lan-net (public)
```

- **(public)**: Resolved from homelab-subflake
- **(private)**: Resolved from private-modules
- **is a stub**: Service/trait exists in data but has no implementation

## Discovering Host Information

### Via Data Passthrough

homelab-subflake exposes data-flake's data for easy access:

```bash
# List services on lithium
nix eval .#data.hosts.all.lithium.servicesAt

# List traits on lithium
nix eval .#data.hosts.all.lithium.traitsAt

# Get lithium's backbone-inner IP
nix eval .#data.hosts.all.lithium.networks.backbone-inner.ipv4
```

### Via Build Traces

Enable debug mode to see what gets included:

```nix
mkHost {
  hostName = "lithium";
  debug = true;  # Enables trace output
}
```

### Via NixOS Configuration

Evaluate the final config to see what's enabled:

```bash
# Check if a service is enabled
nix eval .#nixosConfigurations.lithium.config.services.gitea.enable

# List all systemd services
nix eval .#nixosConfigurations.lithium.config.systemd.services --apply 'builtins.attrNames'
```

## Data Flow

```
data-flake (source of truth)
  ├─ hosts.all.${hostName}.servicesAt
  ├─ hosts.all.${hostName}.traitsAt
  └─ hosts.all.${hostName}.networks.*
         ↓
homelab-subflake.mkHost
  ├─ Resolves services → serviceModules (public) or private-modules (private)
  ├─ Resolves traits → traitModules (public) or private-modules (private)
  └─ Resolves secrets → private-modules.secretModules
         ↓
nixosConfigurations.${hostName}
  └─ Final NixOS system configuration
```

## Adding a Service to a Host

To deploy a service on a host:

1. **Add service to data-flake** `hosts.all.${hostName}.servicesAt`
2. Write the service code
3. **Deploy** via `deploy-$hostname` devshell command

## Adding a Trait to a Host

To apply a configuration trait:

1. **Add trait to data-flake** `hosts.all.${hostName}.traitsAt`
2. **Deploy** via `deploy-$hostname` devshell command

Traits are data-driven (no blanket imports) and resolved the same way as
services.

## Related Documentation

- [MANIFEST-NIX.md](MANIFEST-NIX.md): Service manifest format
- [DNS.md](DNS.md): How DNS zones are generated from host assignments
- [METRICS.md](METRICS.md): How metrics endpoints are discovered
