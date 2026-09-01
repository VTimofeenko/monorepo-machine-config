# `package.json` / `package-lock.json` overrides

These two files replace the ones from the upstream ExcaliDash release inside
`../excalidash-backend.nix`'s build (`patchedManifests`) — they are **not**
copies of what upstream ships, they're a deliberate one-line bump on top of
it: `prisma` and `@prisma/client` moved from upstream's pinned `^5.22.0` to
the exact version nixpkgs' `prisma_6`/`prisma-engines_6` packages provide
(`6.19.3`), plus whatever the rest of `npm install` resolved from that.

## Why

nixpkgs only ships Prisma engine binaries for major versions 6 and 7
(`prisma-engines_6`, `prisma-engines`) — there's no `prisma-engines_5`. Those
engine binaries have to match the `prisma`/`@prisma/client` major version
exactly (confirmed by a real failed build, not a hunch: pointing
`prisma_6`'s engines at a `@prisma/client ^5.22.0` install throws
`ENOENT: ... wasm-compiler-edge.js` — the generator expects a runtime file
5.22 doesn't ship). Since this module deliberately avoids adding any new
flake input (no `nix-prisma-utils` or similar to fetch other engine
versions), bumping to nixpkgs' own `6.19.3` is the only hermetic option that
doesn't touch the network during the build.

This *is* a real dependency version bump, not a patch that only affects the
Nix build — see `../excalidash-backend.nix`'s `postPatch` for the two
`Uint8Array.from(...)` fixes it also required (Prisma 6 tightened the
generated `Bytes` field type; a type-checker-only change, no runtime
behavior difference).

## Regenerating on a version bump

When bumping `excalidash-backend`/`excalidash-frontend` to a new upstream
release (e.g. via `nix-update`), this override has to be regenerated against
that release's real `package.json`, not hand-edited:

```bash
# 1. Get upstream's package.json/package-lock.json for the target tag:
git clone --branch v<new-version> --depth 1 \
  https://github.com/ZimengXiong/ExcaliDash /tmp/excalidash-src
cd /tmp/excalidash-src/backend

# 2. Bump prisma + @prisma/client to whatever nixpkgs' prisma_6 (or newer
#    major, if that's what's current) actually is:
nix eval nixpkgs#prisma_6.version --raw   # confirm the exact version
npm pkg set dependencies.@prisma/client=<that version> \
            devDependencies.prisma=<that version>

# 3. Regenerate the lockfile for real (do not hand-edit it) — this needs
#    real network access:
npm install --package-lock-only

# 4. Copy both files back over these two:
cp package.json package-lock.json \
  <this repo>/flake-modules-prime/excalidash/packages/patches/

# 5. Rebuild and fix forward: a Prisma major bump can reintroduce the same
#    kind of generated-type strictness change the current
#    Uint8Array.from() patches work around — re-check
#    ../excalidash-backend.nix's `postPatch` still applies/still compiles.
```

If upstream ever moves onto a `prisma`/`@prisma/client` major nixpkgs
already ships engines for, drop this whole override (and swap
`prisma_6`/`prisma-engines_6` in `../excalidash-backend.nix` for the
matching unversioned/newer attribute) instead of maintaining a bump forever.
