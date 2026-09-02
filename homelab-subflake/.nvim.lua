-- Project-local `nixd` override that enables `lib.homelab` function inline
-- completion
--
-- Implementation note:
-- `vim.lsp.config()` deep-merges repeated calls, so this only replaces
-- `nixpkgs.expr` – `cmd`, `capabilities`, `options.home_manager,` etc. all
-- still come from the shared config.
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

-- Adds homelab functions to Noogle telescope picker.
--
-- See `noogle.nix` implementation notes on how to regenerate this.
vim.g.noogle_extra_data = vim.fn.expand("~/.cache/noogle-homelab-docs.json")
