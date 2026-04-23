# LubeLogger

Self-hosted vehicle maintenance and fuel mileage tracker.

## Overview

LubeLogger tracks service history, fuel logs, and maintenance reminders for
vehicles.

Access: `https://lubelogger.srv.<publicDomain>`

## Documentation

- [Official Docs](https://docs.lubelogger.com)

## Implementation Notes

- Storage: `/var/lib/lubelogger`, mounted from a disk
- The NixOS module defaults to listening on `localhost`; the `endpointsConfig`
  overrides `Kestrel__Endpoints__Http__Url` via `settings` to bind to the
  backbone-inner interface instead.
- The age secret `lubelogger-env` must contain the full Postgres connection
  string.
