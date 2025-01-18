/**
  A simple TOML language setup.

  Features:
  - taplo :: for formatting and linting
*/
{ pkgs, lib, ... }:
{
  plugins = [
    pkgs.vimPlugins.nvim-jqx
    pkgs.vimPlugins.SchemaStore-nvim
  ];
  config =
    # lua
    ''
      require("lspconfig").taplo.setup({
        cmd = { "${lib.getExe pkgs.taplo}", "lsp", "stdio" },
      })
    '';
}
