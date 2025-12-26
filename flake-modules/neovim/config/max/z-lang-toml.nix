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
    # Lua
    ''
    vim.lsp.config.taplo = {
      cmd = { "${lib.getExe pkgs.taplo}", "lsp", "stdio" },
    }
    vim.lsp.enable('taplo')
    '';
}
