# NixOS module that configures zsh
{ self, ... }:
{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (import ../../config { inherit lib pkgs self; }).nixosModule
  ];
}
