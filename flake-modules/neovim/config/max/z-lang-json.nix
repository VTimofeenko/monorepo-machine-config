/**
  A simple JSON language setup.

  Features:
  - jsonls :: for formatting and linting
  - jqx :: quickfix keys and json path evaluator
  - schemas support
*/
{ pkgs, ... }:
{
  plugins = [
    pkgs.vimPlugins.nvim-jqx
    pkgs.vimPlugins.SchemaStore-nvim
  ];
  config =
    # lua
    ''
    require("lspconfig").jsonls.setup({
      cmd = { '${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server', '--stdio'  },
      settings = {
        json = {
          schemas = require("schemastore").json.schemas {
            select = {
              "Renovate",
            },
          },
          validate = { enable = true, },
        },
      },
    })
  '';
  extraPackages = [ pkgs.jq ];
}
