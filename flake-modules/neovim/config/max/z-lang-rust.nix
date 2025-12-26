/**
  A simple rust_analyzer language server setup.
*/
{ pkgs-unstable, lib, ... }:
{
  config =
    # Lua
    ''
    vim.lsp.config.rust_analyzer = {
      cmd = { "${lib.getExe pkgs-unstable.rust-analyzer}"},
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
    }
    vim.lsp.enable('rust_analyzer')
    '';
}
