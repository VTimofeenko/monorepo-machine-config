# NixOS module that configures zsh
{ self, ... }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  commonSettings = import ../common { inherit pkgs config self; };
in
{
  imports = [
    (import ../../config { inherit lib pkgs self; }).nixosModule
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = lib.mkForce false;
    interactiveShellInit =
      commonSettings.initExtra
      + "\n";
  };
  environment = {
    inherit (commonSettings) variables;
  };
}
