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
    }
    vim.lsp.enable('beancount')
  '';
}
