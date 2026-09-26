/**
  ExcaliDash backend (Node/Express + Prisma).

  ExcaliDash isn't packaged in nixpkgs, so this fetches the upstream release
  tag straight from GitHub and builds it directly — no vendored copy of the
  source lives in this repo. Two things this derivation deliberately does
  differently than upstream's Docker image:

  - Only one Prisma migration set (`databaseProvider`) is shipped per build —
    the runtime sqlite/postgresql migration-copy dance in their
    `docker-entrypoint.sh` is dropped entirely; the provider is baked in at
    build time instead. `./excalidash-backend-sqlite.nix` is the sqlite
    variant of this same derivation (`callPackage ./excalidash-backend.nix {
    databaseProvider = "sqlite"; }`) — the two aren't runtime-switchable
    (Prisma generates a provider-specific client), so pick whichever one
    matches `services.excalidash.database.type` (../nixos-module.nix).
  - Prisma's engine binaries are pulled from nixpkgs' `prisma-engines` instead
    of letting `prisma generate`/`migrate deploy` download them from
    binaries.prisma.sh — required for a hermetic Nix build (no network in the
    sandbox), and avoids adding any new flake input. This mirrors nixpkgs'
    own `linkwarden` package (`pkgs/by-name/li/linkwarden/package.nix`),
    which solves the identical problem for the same generator
    (`prisma-client-js`, no driver adapters).

  See `./patches/README.md` for what/why on the `package.json`/
  `package-lock.json` overrides below, and how to regenerate them on a
  version bump.
*/
{
  lib,
  runCommand,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  python3,
  prisma_6,
  prisma-engines_6,
  makeWrapper,
  # "postgresql" (default) or "sqlite" — see ./excalidash-backend-sqlite.nix.
  databaseProvider ? "postgresql",
}:
assert lib.assertOneOf "databaseProvider" databaseProvider [
  "postgresql"
  "sqlite"
];
let
  version = "0.6.0";

  # `rev = "v${version}"` (rather than a bare commit hash) is what lets
  # `nix-update excalidash-backend` bump this on its own.
  excalidashSrc = fetchFromGitHub {
    owner = "ZimengXiong";
    repo = "ExcaliDash";
    rev = "v${version}";
    hash = "sha256-oTLrSJiuhD/FQOayXevbNFlBmgaTvsQqlcZByt/PafM=";
  };

  # Upstream pins `prisma`/`@prisma/client` to ^5.22.0; nixpkgs only ships
  # engines for major 6/7, and the two aren't wire-compatible (prisma_6's
  # generator expects a @prisma/client runtime file 5.22 doesn't ship —
  # confirmed by an actual failed build, not a hunch). Bumping to the exact
  # nixpkgs-provided 6.19.3 is a one-line, non-breaking change for this
  # schema (classic `prisma-client-js` generator, no driver adapters, no
  # `previewFeatures`) — see `./patches/README.md`.
  patchedManifests = [
    ./patches/package.json
    ./patches/package-lock.json
  ];

  src = runCommand "excalidash-backend-src" { } ''
    cp -r ${excalidashSrc}/backend $out
    chmod -R u+w $out
    ${lib.concatMapStringsSep "\n" (f: "cp ${f} $out/${builtins.baseNameOf f}") patchedManifests}
  '';
in
buildNpmPackage (finalAttrs: {
  pname = "excalidash-backend" + lib.optionalString (databaseProvider == "sqlite") "-sqlite";
  inherit version;

  inherit src;

  nodejs = nodejs_22;

  # `better-sqlite3` is an unconditional `dependencies` entry regardless of
  # `databaseProvider` — it's unrelated to Prisma's own sqlite/postgresql
  # datasource selection, only used as a fallback for Node's built-in
  # `node:sqlite` for the legacy-import feature (opening someone else's raw
  # sqlite export file directly) — so `npm ci` always compiles its native
  # addon.
  nativeBuildInputs = [
    python3
    makeWrapper
    prisma_6
  ];

  npmDepsHash = "sha256-krcbe+AbCAYpc1VNE3ftE2BsODR7EscF7kHl2Rx2tYY=";

  # `uploads/` is only used as multer's temp-staging dir for file uploads and
  # sqlite-import staging (actual drawing data lives in Postgres, or S3 when
  # configured) — but its path is hardcoded relative to the compiled
  # `dist/index.js`, which lands read-only in the Nix store. Redirect it to
  # `$XDG_DATA_HOME/uploads` (falling back to the original relative path when
  # unset, so this package still runs standalone/outside NixOS) instead of
  # baking in a specific absolute path here — `../nixos-module.nix` points
  # `XDG_DATA_HOME` at the unit's own `$STATE_DIRECTORY` at runtime, so this
  # package makes no assumption about what that directory is actually named
  # or where it lives (friendlier to e.g. a template unit / a different
  # `StateDirectory`, and doesn't need rebuilding if that ever changes).
  postPatch = ''
    # Upstream's API-key scope check (`getApiKeyRouteResource`) never
    # recognizes `/files/*` as a resource at all, so an API key request to
    # it always 403s/404s regardless of scopes — even though the exact same
    # request with a session cookie works fine. That blocks both fetching
    # an embedded image (GET /files/:drawingId/:fileId) and uploading one
    # (PUT /drawings/:drawingId/files/:fileId) via API key. Maps both onto
    # the existing `drawings:read`/`drawings:write` scopes rather than
    # inventing a new scope category the account-settings UI doesn't know
    # about. See ./patches/api-key-files-scope.patch (same diff, kept
    # standalone so it's easy to open as an upstream PR) and
    # flake-modules-prime/excalidash-mcp-server/src/excalidash_mcp/client.py
    # for where this was found (get_file couldn't fetch anything).
    # -p2: the patch's paths are `a/backend/...`/`b/backend/...` (rooted at
    # the full upstream repo, so it applies as-is against a checkout for an
    # upstream PR), but this derivation's source root is already `backend/`.
    patch -p2 < ${./patches/api-key-files-scope.patch}

    substituteInPlace src/index.ts \
      --replace-fail \
        'path.resolve(__dirname, "../uploads")' \
        '(process.env.XDG_DATA_HOME ? path.join(process.env.XDG_DATA_HOME, "uploads") : path.resolve(__dirname, "../uploads"))'

    # The 5.x -> 6.19.3 bump (see `patchedManifests` above) tightens the
    # generated type for Prisma `Bytes` fields from accepting any
    # `ArrayBufferLike`-backed view to requiring `Uint8Array<ArrayBuffer>`
    # specifically — a Node `Buffer` (backed by `ArrayBufferLike`, which also
    # covers `SharedArrayBuffer`) no longer satisfies it. `Uint8Array.from`
    # copies into a fresh, concretely-`ArrayBuffer`-backed view; the copy is
    # of already-decoded image bytes, bounded by the app's own upload size
    # limits, so it isn't a meaningful cost. No behavior change otherwise —
    # this is a type-checker-only mismatch, not a runtime one.
    substituteInPlace src/fileProcessing.ts \
      --replace-fail 'data: decoded.buffer,' 'data: Uint8Array.from(decoded.buffer),'
    substituteInPlace src/routes/files.ts \
      --replace-fail 'data: body,' 'data: Uint8Array.from(body),'
  '';

  env = {
    # Classic (non driver-adapter) `prisma-client-js` generator — the
    # `binaryTargets` list in schema.prisma (musl targets, for their Alpine
    # image) is irrelevant here: these env vars make Prisma use the given
    # binaries directly instead of resolving/downloading anything itself.
    PRISMA_CLIENT_ENGINE_TYPE = "binary";
    PRISMA_QUERY_ENGINE_LIBRARY = "${prisma-engines_6}/lib/libquery_engine.node";
    PRISMA_QUERY_ENGINE_BINARY = "${prisma-engines_6}/bin/query-engine";
    PRISMA_SCHEMA_ENGINE_BINARY = "${prisma-engines_6}/bin/schema-engine";
  };

  # `npm run build` in package.json is `prisma generate && tsc` — reimplemented
  # here so we can pin the datasource provider first (their build script
  # relies on `DATABASE_PROVIDER` being set at runtime, which this module
  # doesn't do — the provider is fixed per-build, see `databaseProvider`).
  buildPhase = ''
    runHook preBuild

    sed -i \
      -e '/datasource db {/,/}/ s/provider = env("[^"]*")/provider = "${databaseProvider}"/' \
      -e '/datasource db {/,/}/ s/provider = "[^"]*"/provider = "${databaseProvider}"/' \
      prisma/schema.prisma

    npx prisma generate
    npx tsc

    # Prisma emits the generated client as plain JS/`.d.ts` under
    # src/generated; tsc doesn't copy it (mirrors their own Dockerfile, which
    # does this same copy explicitly for the same reason).
    cp -r src/generated dist/generated

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/excalidash
    cp -r dist node_modules package.json $out/share/excalidash/
    mkdir -p $out/share/excalidash/uploads

    # Only this build's own provider's migration set — no runtime switching.
    mkdir -p $out/share/excalidash/prisma
    cp -r prisma/migrations/${databaseProvider} $out/share/excalidash/prisma/migrations
    cp prisma/schema.prisma $out/share/excalidash/prisma/schema.prisma

    makeWrapper ${nodejs_22}/bin/node $out/bin/excalidash-server \
      --add-flags "$out/share/excalidash/dist/index.js" \
      --set-default PRISMA_CLIENT_ENGINE_TYPE "binary" \
      --set-default PRISMA_QUERY_ENGINE_LIBRARY "${prisma-engines_6}/lib/libquery_engine.node" \
      --set-default PRISMA_QUERY_ENGINE_BINARY "${prisma-engines_6}/bin/query-engine" \
      --set-default PRISMA_SCHEMA_ENGINE_BINARY "${prisma-engines_6}/bin/schema-engine" \
      --set-default DATABASE_PROVIDER "${databaseProvider}"

    makeWrapper ${lib.getExe prisma_6} $out/bin/excalidash-migrate \
      --add-flags "migrate deploy --schema $out/share/excalidash/prisma/schema.prisma" \
      --set-default PRISMA_CLIENT_ENGINE_TYPE "binary" \
      --set-default PRISMA_QUERY_ENGINE_LIBRARY "${prisma-engines_6}/lib/libquery_engine.node" \
      --set-default PRISMA_QUERY_ENGINE_BINARY "${prisma-engines_6}/bin/query-engine" \
      --set-default PRISMA_SCHEMA_ENGINE_BINARY "${prisma-engines_6}/bin/schema-engine"

    runHook postInstall
  '';

  meta = {
    description = "ExcaliDash backend API (Express + Prisma, ${databaseProvider})";
    mainProgram = "excalidash-server";
    # No real restriction: nodejs_22, prisma_6 and prisma-engines_6 (the
    # only platform-sensitive deps here) all cover more than x86_64-linux —
    # confirmed by a real `nix build .#packages.aarch64-linux.excalidash-backend`.
    platforms = lib.platforms.linux;
  };
})
