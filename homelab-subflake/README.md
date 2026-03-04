This subflake's main goal is to produce deployable machine configurations for my
homelab.

# Terminology

- **HOST**: a physical or virtual machine running one ore mote **SERVICE**s.
- **SERVICE**: a deployed homelab service with a manifest. Has side effects (DNS
  entries, dashboard links, monitoring targets, etc.). Mapped to hosts via
  data-flake `servicesAt`.
- **TRAIT**: a NixOS configuration module applied to hosts. Mapped to
  hosts via data-flake `traitsAt`, is effectful
- **MODULE**: a NixOS configuration module that only provides an implementation
  and has no effect on its own (exactly like standard NixOS module)

# Architecture

Four flakes:

1. `data-flake`: contains data on hosts services and networks, produces raw data and
   internal `lib.homelab` functions. Private to mask existence and mapping of
   services to hosts.

2. `private-modules`: contains implementations of TRAITs SERVICEs and MODULEs that
   should not be public for whatever reason

3. `base`: the top-level flake of this repository. Contains easily reusable
   modules with few dependencies

4. `homelab`: this flake. Gathers outputs from other flakes, produces NixOS and
   other configurations
