/**
  A simple bash language server setup.

  Includes:
  - `shfmt` :: to format scripts
  - `shellcheck` :: to make the editor very angry
*/
{ pkgs, lib, ... }:
{
  config = /* Lua */ ''
    vim.lsp.config.bashls = {
      cmd = { '${lib.getExe pkgs.bash-language-server}', 'start'  },
      autostart = true,
      capabilities = caps,
      single_file_support = true,
      filetypes = { "zsh", "bash", "sh" },
      settings = {
        bashIde = {
          shfmt = {
            path = "${lib.getExe pkgs.shfmt}"
          },
          shellcheckPath = "${lib.getExe pkgs.shellcheck}"
        },
      },
      on_attach = function(bufnr)
        vim.api.nvim_buf_set_keymap(0, 'n', "<localleader><Return>", "<Cmd>!\"%:p\"<CR>", {desc = "Run this file" })
      end,
    }
    vim.lsp.enable('bashls')
  '';
}
