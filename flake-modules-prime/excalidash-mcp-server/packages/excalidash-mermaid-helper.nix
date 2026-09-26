/**
  Small headless CLI: Mermaid source on stdin -> Excalidraw elements JSON on
  stdout. Wraps `@excalidraw/mermaid-to-excalidraw`, which is a browser
  library — see `../mermaid-helper/convert.mjs` for the jsdom shimming this
  needs and what's approximate about the result. Used by the
  `excalidash-mcp-server` Python package as a subprocess.
*/
{
  lib,
  buildNpmPackage,
  nodejs_22,
  makeWrapper,
}:

buildNpmPackage {
  pname = "excalidash-mermaid-helper";
  version = "1.0.0";

  src = ../mermaid-helper;

  npmDepsHash = "sha256-I8FI7dr708kX3bpAI2/w+pPeDJ4JUHgWRPCiRrZyUF8=";

  nodejs = nodejs_22;

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/excalidash-mermaid-helper
    cp -r node_modules $out/lib/excalidash-mermaid-helper/node_modules
    cp convert.mjs $out/lib/excalidash-mermaid-helper/convert.mjs
    mkdir -p $out/bin
    makeWrapper ${lib.getExe' nodejs_22 "node"} $out/bin/excalidash-mermaid-helper \
      --add-flags $out/lib/excalidash-mermaid-helper/convert.mjs
    runHook postInstall
  '';

  meta = {
    description = "Mermaid -> Excalidraw elements conversion CLI (headless)";
    mainProgram = "excalidash-mermaid-helper";
  };
}
