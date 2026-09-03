-- Project-local `nixd` override that enables `lib.homelab` function inline
-- completion
--
-- Implementation note:
-- `vim.lsp.config()` deep-merges repeated calls, so this only replaces
-- `nixpkgs.expr` – `cmd`, `capabilities`, `options.home_manager,` etc. all
-- still come from the shared `config`.
vim.lsp.config("nixd", {
  settings = {
    nixd = {
      nixpkgs = {
        expr = [[
          let
            flakeRef = "github:VTimofeenko/monorepo-machine-config";
            pkgs = import (builtins.getFlake flakeRef).inputs.nixpkgs { };
            homelab = (builtins.getFlake "${flakeRef}?dir=homelab-subflake").inputs.data-flake.lib.homelab;
          in
          pkgs // { lib = pkgs.lib.extend (_: _: { inherit homelab; }); }
        ]],
      },
    },
  },
})

-- Register `lib.homelab` docs with NixLibDocs telescope picker
local ok, nix_lib_docs = pcall(require, "nix-lib-docs")
if ok then
  local prj_root = vim.env.PRJ_ROOT or vim.fs.root(0, { ".git" }) or vim.fn.getcwd()
  local subflake_dir = prj_root:match("/homelab%-subflake$") and prj_root or (prj_root .. "/homelab-subflake")
  local repo_root = prj_root:gsub("/homelab%-subflake$", "")

  nix_lib_docs.register_source("homelab", {
    cwd = subflake_dir,
    expr = string.format(
      [[(builtins.getFlake "path:%s?dir=homelab-subflake").inputs.data-flake.packages.${builtins.currentSystem}.homelab-lib-docs]],
      repo_root
    ),
  })
end
