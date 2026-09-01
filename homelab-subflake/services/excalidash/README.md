# ExcaliDash

Self-hosted multi-user dashboard for Excalidraw drawings, with realtime
collaboration, collections, sharing, and versioned history.

## Overview

ExcaliDash isn't packaged in nixpkgs — the backend (Express + Prisma) and
frontend (Vite/React SPA) are built directly from the vendored source under
`pkgs/`. Notable departures from upstream's own Docker-based deployment:

- Only Postgres is supported; the sqlite provider and upstream's
  runtime migration-set-switching are not wired up.
- Prisma's query/schema engine binaries come from nixpkgs' `prisma-engines`
  package (env-var override) instead of being downloaded from
  `binaries.prisma.sh` — required for the Nix build to be hermetic, and
  avoids adding a flake input for it.
- The frontend/backend split is served by this host's own local nginx
  instead of upstream's separate nginx container + `nginx.conf.template`
  placeholder substitution.
- OIDC login and S3 file storage are supported upstream but not configured
  here — this ships local-password auth with drawing files stored as bytes
  in Postgres. Both can be added by extending
  `systemd.services.excalidash-backend` in `excalidash.nix`.

## Manual deploy step

`database.create = true` provisions the `excalidash` Postgres role/database,
but (matching every other service on this shared `db` host) its password is
**not** managed by Nix — set it once, manually, to match the
`excalidash-db-password` secret:

```sql
ALTER ROLE excalidash PASSWORD '<contents of the decrypted excalidash-db-password secret>';
```

## Documentation

- [Upstream README](https://github.com/ZimengXiong/ExcaliDash)
- [Environment variables reference](https://github.com/ZimengXiong/ExcaliDash/blob/main/docs/CONFIGURATION.md)
