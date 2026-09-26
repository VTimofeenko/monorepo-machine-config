/**
  MCP server exposing an ExcaliDash instance's drawings/collections REST API
  as tools (list/get/create/update drawings and collections, plus Mermaid ->
  Excalidraw conversion via `excalidash-mermaid-helper`). Uses the plain
  `mcp` package's bundled `mcp.server.fastmcp.FastMCP` — no need for the
  separate third-party `fastmcp` framework/its nixpkgs-lagging deps (compare
  `../prometheus-mcp-server/package.nix`).

  Configuration is via environment variables (see `./nixos-module.nix` for
  the systemd wiring): `EXCALIDASH_URL`, `EXCALIDASH_API_KEY`,
  `EXCALIDASH_MCP_TRANSPORT` (stdio/sse/streamable-http, default stdio),
  `EXCALIDASH_MCP_HOST`/`EXCALIDASH_MCP_PORT`.
*/
{
  pkgs,
  python3Packages,
  makeWrapper,
  resvg,
  liberation_ttf,
}:

let
  # Not taken as a callPackage arg: auto-discovered sibling packages land in
  # `perSystem.overlayAttrs`, which doesn't feed back into the `pkgs` used to
  # evaluate `perSystem.packages` itself (no self-referential fixpoint there) —
  # so `pkgs.excalidash-mermaid-helper` isn't resolvable at this point even
  # though `nix build .#excalidash-mermaid-helper` works fine. Build it
  # directly from its own file instead.
  excalidash-mermaid-helper = pkgs.callPackage ./packages/excalidash-mermaid-helper.nix { };
in

python3Packages.buildPythonApplication {
  pname = "excalidash-mcp-server";
  version = "0.1.0";
  pyproject = true;

  src = ./src;

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    mcp
    httpx
  ];

  nativeBuildInputs = [ makeWrapper ];

  # The Python side shells out to the Node helper and to `resvg` by bare
  # name (PATH lookup, mermaid helper overridable via
  # EXCALIDASH_MERMAID_HELPER) — bake both into PATH so the package works
  # standalone without the caller having to know about either. Also bakes
  # in a bundled font for resvg (see render.py's _font_args): without one,
  # rendered text silently vanishes rather than erroring, since resvg has
  # no font to rasterize glyphs with and there's no system fontconfig setup
  # to fall back on in a Nix-built closure.
  postFixup = ''
    wrapProgram $out/bin/excalidash-mcp-server \
      --prefix PATH : ${excalidash-mermaid-helper}/bin \
      --prefix PATH : ${resvg}/bin \
      --set-default EXCALIDASH_RENDER_FONTS_DIR ${liberation_ttf}/share/fonts/truetype
  '';

  doCheck = false;

  meta = {
    description = "MCP server for a self-hosted ExcaliDash instance";
    mainProgram = "excalidash-mcp-server";
  };
}
