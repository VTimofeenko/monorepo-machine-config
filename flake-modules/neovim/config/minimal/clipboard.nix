/** Configures clipboard share contents with the rest of the system. */
{ pkgs, lib, ... }:
{
  config = ''
    vim.opt.clipboard = 'unnamed${lib.optionalString pkgs.stdenv.isLinux "plus"}'
  '';
}
