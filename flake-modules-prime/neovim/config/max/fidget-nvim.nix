{ pkgs, ... }:
{
  plugin = pkgs.vimPlugins.fidget-nvim;
  config = "require('fidget').setup {}";
}
