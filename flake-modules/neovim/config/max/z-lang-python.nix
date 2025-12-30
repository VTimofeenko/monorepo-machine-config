/**
  Python configuration for neovim.
*/
{
  pkgs,
  lib,
  self,
  ...
}:
let
  efmPythonConfig =
    {
      version = 2;
      root-markers = [ ".git/" ];
      languages.python = [
        {
          format-command = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.python-formatter} -";
          format-stdin = true;

          lint-command = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.python-linter} -";
          lint-stdin = true;
          lint-after-open = true;
          lint-ignore-exit-code = true;
          lint-on-save = true;
          lint-formats = [
            "%f:%l:%c: %m"
          ];
        }
      ];
    }
    |> (pkgs.formats.yaml { }).generate "efm-config.yaml";
in
{
  config = # Lua
    ''
      -- Register a custom efm instance for python to avoid conflicts
      local configs = require 'lspconfig.configs'
      if not configs.efm_python then
        configs.efm_python = {
          default_config = {
            cmd = { "${lib.getExe pkgs.efm-langserver}", "-c", "${efmPythonConfig}" },
            root_dir = require('lspconfig').util.root_pattern(".git", "."),
            filetypes = { "python" },
          }
        }
      end

      vim.lsp.config.efm_python = {
        cmd = { "${lib.getExe pkgs.efm-langserver}", "-c", "${efmPythonConfig}" },
        settings = {},
        filetypes = {"python"},
      }
      vim.lsp.enable('efm_python')
    '';
}
