/**
  Python configuration for Neovim.
*/
{
  pkgs,
  lib,
  self,
  pkgs-unstable,
  ...
}:
let
  pythonFormatter =
    self.packages.${pkgs.stdenv.hostPlatform.system}.my-python-formatter;
in
{
  config = # Lua
    ''
      vim.lsp.config.ty = {
        cmd = { "${lib.getExe pkgs-unstable.ty}", "server" },
      }
      vim.lsp.enable('ty')

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client.name == "ty" then
            vim.keymap.set('n', '<localleader>f', function()
              local cmd = "${lib.getExe pythonFormatter}"
              local file = vim.api.nvim_buf_get_name(0)
              vim.fn.system(cmd .. " " .. vim.fn.shellescape(file))
              vim.cmd("edit!")
              client.notify("textDocument/didChange", {
                textDocument = { uri = vim.uri_from_bufnr(0), version = 0 },
                contentChanges = {{ text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") }}
              })
            end, { buffer = args.buf, desc = "Python format + ty refresh" })
          end
        end,
      })
    '';
}
