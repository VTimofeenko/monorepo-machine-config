/**
  A Telescope picker for Nix library function documentation (NixLibDocs).

  Packages `plugins/nix-lib-docs.nvim` as a Neovim plugin and extracts
  upstream `pkgs.lib` documentation at package build time using `nixdoc`.

  Dynamic/project-specific docs (such as `lib.homelab`) are registered
  via `.nvim.lua` in their respective repositories using:
    `require("nix-lib-docs").register_source("homelab", { expr = ... })`
  which resolves asynchronously without blocking editor startup.
*/
{ pkgs, ... }:
let
  nix-lib-docs-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "nix-lib-docs-nvim";
    src = ../../plugins/nix-lib-docs.nvim;

    doCheck = false;

    dependencies = [
      pkgs.vimPlugins.telescope-nvim
      pkgs.vimPlugins.plenary-nvim
    ];

    nativeBuildInputs = [
      pkgs.nixdoc
      pkgs.jq
    ];

    postInstall = ''
      mkdir -p $out/data
      for file in ${pkgs.path}/lib/*.nix; do
        name=$(basename "$file" .nix)
        ${pkgs.nixdoc}/bin/nixdoc --json-output \
          --prefix "lib.$name" \
          --category "$name" \
          --description "$name functions" \
          --file "$file" 2>/dev/null || true
      done \
      | ${pkgs.jq}/bin/jq -s 'map(.entries // []) | flatten | map({(.prefix + "." + .name): ((.description // ["No documentation"]) | join("\n\n"))}) | (add // {})' \
      > $out/data/nixpkgs-lib.json
    '';
  };
in
{
  plugin = nix-lib-docs-nvim;

  extraPackages = [
    pkgs.glow
    pkgs.nix
  ];

  config =
    # lua
    ''
      -- Initialize NixLibDocs documentation
      require("nix-lib-docs").load_base_docs()
    '';
}
