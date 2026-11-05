{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  openssl,
  writeText,
  # Postgres design storage (selected at runtime by DATABASE_URL), with TLS for TCP connections
  withPostgres ? false,
  # Faces compiled in next to the bundled ones, for `text(font = family)`:
  # [ { family; file; description ? ""; } ], `file` a TrueType (glyf) font
  extraFonts ? [ ],
}:
let
  # Appended to the `FONTS` table in engine/typeface.rs
  fontEntries = writeText "reopenscad-extra-fonts.rs" (
    lib.concatMapStrings (font: ''
      FontEntry {
          family: ${builtins.toJSON font.family},
          style: "Regular",
          bold: false,
          italic: false,
          license: OFL,
          description: ${builtins.toJSON (font.description or "")},
          data: include_bytes!("fonts/${baseNameOf font.file}"),
      },
    '') extraFonts
  );
in
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

  postPatch = lib.optionalString (extraFonts != [ ]) ''
    ${lib.concatMapStrings (font: ''
      cp ${font.file} src/engine/fonts/${baseNameOf font.file}
    '') extraFonts}
    awk -v entries=${fontEntries} '
      in_fonts && /^];/ { while ((getline line < entries) > 0) print line; in_fonts = 0; done = 1 }
      /^pub static FONTS/ { in_fonts = 1 }
      { print }
      END { exit !done }
    ' src/engine/typeface.rs > typeface.rs && mv typeface.rs src/engine/typeface.rs
  '';

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
