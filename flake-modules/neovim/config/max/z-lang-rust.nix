/**
  A simple rust_analyzer language server setup.
*/
{ pkgs, lib, ... }:
{
  config =
    # lua
    ''
      require("lspconfig").rust_analyzer.setup({
        cmd = { "${lib.getExe pkgs.rust-analyzer}"},
        autostart = true,
        capabilities = caps,
        settings = {
          ["rust-analyzer"] = {
            imports = {
              granularity = {
                group = "module",
              },
              prefix = "self",
            },
            cargo = {
              buildScripts = {
                enable = true,
              },
            },
            procMacro = {
              enable = true,
            },
            checkOnSave = true,
          },
        },
      })
    '';
}
