# Chhoto URL

LAN-only URL shortener used as a stable target for printed and 3D-printed QR
codes.

## Overview

QR codes point at `https://qr.srv.<publicDomain>/<slug>`; the slug's target can
be changed later without reprinting.

## Documentation

- [Upstream](https://github.com/SinTan1729/chhoto-url)

## Implementation Notes

- No app-level auth: access is limited to `humanPersonalDevices` at the SSL
  proxy. Guest devices get a 403.
- Redirects are `TEMPORARY` (307) with `no-cache` so browsers don't pin old
  targets.
- Use short uppercase slugs: an all-uppercase URL fits QR alphanumeric mode,
  giving a smaller code with larger modules (better for 3D prints).
- Only works where `*.srv` resolves to the LAN (not on cellular, Android
  Private DNS, or iCloud Private Relay).
