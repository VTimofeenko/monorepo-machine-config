/**
  ExcaliDash static frontend (Vite/React SPA).

  Client-side default is `API_URL = "/api"` (frontend/src/api/client.ts), so
  the build is deployment-agnostic — no `VITE_*` backend-URL baking needed.
  `services.excalidash.nginx` (../nixos-module.nix) is what actually serves
  this and splits `/api` + `/socket.io` off to the backend — not upstream's
  own nginx-in-a-container + `nginx.conf.template` placeholder substitution.
*/
{
  lib,
  runCommand,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:

let
  version = "0.6.0";

  # Same pin as ./excalidash-backend.nix — kept per-file (rather than
  # shared) since each package here is independently `callPackage`-able;
  # identical rev+hash means Nix only actually fetches it once. `rev =
  # "v${version}"` (not a bare commit hash) is what lets `nix-update
  # excalidash-frontend` bump this on its own.
  excalidashSrc = fetchFromGitHub {
    owner = "ZimengXiong";
    repo = "ExcaliDash";
    rev = "v${version}";
    hash = "sha256-oTLrSJiuhD/FQOayXevbNFlBmgaTvsQqlcZByt/PafM=";
  };
in
buildNpmPackage (finalAttrs: {
  pname = "excalidash-frontend";
  inherit version;

  # `lib.fileset` needs a real `Path` value for `root`/its fileset members;
  # `fetchFromGitHub`'s result is a derivation (a string-like value once
  # interpolated), so compose the two pieces we want with `runCommand`
  # instead — same approach as ../packages/excalidash-backend.nix's `src`.
  src = runCommand "excalidash-frontend-src" { } ''
    mkdir -p $out
    cp -r ${excalidashSrc}/frontend $out/frontend
    cp ${excalidashSrc}/VERSION $out/VERSION
  '';

  sourceRoot = "${finalAttrs.src.name}/frontend";

  nodejs = nodejs_22;

  npmDepsHash = "sha256-Q0NrOfakCI5IrogB9pEP5iZqP4xCAHufrQxo7ra/hFc=";

  # `npm run build` is `tsc -b && vite build && copy-excalidraw-assets.mjs --dist`
  # — the default buildNpmPackage build phase (`npm run build`) is fine as-is.

  installPhase = ''
    runHook preInstall
    cp -r dist $out
    runHook postInstall
  '';

  meta = {
    description = "ExcaliDash static frontend (Vite/React SPA)";
    platforms = [ "x86_64-linux" ];
  };
})
