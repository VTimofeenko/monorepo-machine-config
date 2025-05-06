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
          format-command = "${lib.getExe self.packages.${pkgs.system}.python-formatter} -";
          format-stdin = true;

          lint-command = "${lib.getExe self.packages.${pkgs.system}.python-linter} -";
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
  config = # lua
    ''
      require("lspconfig").efm.setup{
        cmd = { "${lib.getExe pkgs.efm-langserver}", "-c", "${efmPythonConfig}" },
        settings = {},
        filetypes = {"python"},
      }
    '';
}
