{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  openssl,
  # Postgres design storage (selected at runtime by DATABASE_URL), with TLS for TCP connections
  withPostgres ? false,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "reopenscad";
  version = "0-unstable-2026-11-02";

  src = fetchFromGitHub {
    owner = "Matvey-Kuk";
    repo = "reopenscad";
    rev = "badb954997e58fd0f1fd568af22c0cadab5820fa";
    hash = "sha256-8CRyAseNPU6VAfB8bHc+WDD9mU64DAydhTkCRE7LWJE=";
  };

  sourceRoot = "${finalAttrs.src.name}/web/backend";

  cargoHash = "sha256-H1curkDCO1ydjP+BBKMZbihI3VQygqOjgoivjXh1LwA=";

  buildFeatures = lib.optional withPostgres "postgres-tls";

  nativeBuildInputs = [ makeWrapper ] ++ lib.optional withPostgres pkg-config;
  buildInputs = lib.optional withPostgres openssl;

  # Test suite renders the full OpenSCAD golden corpora; too slow for a package build
  doCheck = false;

  # Browser shell, served from REOPENSCAD_WEB_ROOT (same set as upstream Dockerfile)
  postInstall = ''
    mkdir -p $out/share/reopenscad/web
    cp -r ../index.html ../app.js ../styles.css ../legacy-assets ../logos ../media ../examples \
      $out/share/reopenscad/web/
    wrapProgram $out/bin/reopenscad-server \
      --set-default REOPENSCAD_WEB_ROOT $out/share/reopenscad/web
  '';

  meta = {
    description = "OpenSCAD-compatible browser workbench on an independent Rust geometry engine";
    homepage = "https://github.com/Matvey-Kuk/reopenscad";
    license = lib.licenses.gpl3Plus;
    mainProgram = "reopenscad-server";
  };
})
