# Vaultwarden

Bitwarden-compatible password manager server.

## Overview

Lightweight Rust reimplementation of the Bitwarden server API. Works with the
official Bitwarden browser extensions, desktop and mobile apps — point them at
the self-hosted server URL.

## Documentation

- [Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Configuration reference (`.env.template`)](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template)
- [SSO with OpenID Connect](https://github.com/dani-garcia/vaultwarden/wiki/Enabling-SSO-support-using-OpenId-Connect)

## Implementation Notes

- Database: PostgreSQL (via db service). The state dir still holds
  attachments, sends and `rsa_key.pem` (JWT signing key — losing it only logs
  everyone out; vault encryption is client-side).
- State dir is `/var/lib/bitwarden_rs`, not `/var/lib/vaultwarden`: the NixOS
  module keeps the legacy name on hosts with `stateVersion` < 24.11. Backups
  list both dirs, so a `stateVersion` bump needs no manifest change.
- Secrets are passed as a single env file (`vaultwarden-env`) containing
  `DATABASE_URL` and `SSO_CLIENT_SECRET`.
- Login: Keycloak SSO alongside master-password login. SSO only
  authenticates; the master password is still required to decrypt the vault.
- Signups are disabled. To create the first account, temporarily set
  `SIGNUPS_ALLOWED = true` (or add `ADMIN_TOKEN` to the env file and invite
  users from `/admin`).
- Websocket notifications (`/notifications/hub`) work through the standard
  SSL proxy vhost, which enables websockets on `/`.
