/**
  A simple TOML language setup.

  Features:
  - taplo :: for formatting and linting
*/
{ pkgs, lib, ... }:
{
  config =
    # Lua
    ''
    vim.lsp.config.taplo = {
      cmd = { "${lib.getExe pkgs.taplo}", "lsp", "stdio" },
    }
    vim.lsp.enable('taplo')
    '';
}
