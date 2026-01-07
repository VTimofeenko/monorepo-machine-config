/**
  A simple beancount server setup.

*/
{ pkgs, lib, ... }:
{
  config = /* Lua */ ''
    vim.lsp.config.beancount = {
      cmd = { '${lib.getExe pkgs.beancount-language-server}', '--stdio'  },
      single_file_support = true,
      filetypes = { "beancount", "bean"},
      init_options = {
        journal_file = vim.fn.findfile("journal.beancount", ".;"),
      },
    }
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "beancount",
      callback = function()
      vim.opt_local.commentstring = "; %s"
    end,
})
    vim.lsp.enable('beancount')
  '';
}
