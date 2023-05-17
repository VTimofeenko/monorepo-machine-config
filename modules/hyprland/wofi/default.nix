# Home manager module to configure wofi
{ pkgs, config, lib, ... }:
{
  programs.wofi =
    {
      enable = true;
    };
}
