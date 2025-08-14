/**
  Set up `ripgrep` for vim :grep command. Mostly used for quickfix list
  population that obeys standard `ripgrep` config (e.g. ignore `.git`). Also
  adds smartcase to grep.
*/
{ pkgs, ... }:
{
  config =
    # lua
    ''
      vim.opt.grepprg = "${pkgs.lib.getExe pkgs.ripgrep} --vimgrep --no-heading --smart-case"
    '';
}
