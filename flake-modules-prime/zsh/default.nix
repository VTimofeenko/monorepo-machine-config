# Flake module that exposes my zsh config as a home manager and NixOS modules
{ self, ... }:
{
  flake = {
    nixosModules.zsh =
      { pkgs, lib, ... }:
      {
        imports = [
          (import ./config { inherit lib pkgs self; }).nixosModule
        ];
      };
    homeManagerModules.zsh =
      { pkgs, lib, ... }:
      {
        imports = [
          (import ./config { inherit lib pkgs self; }).homeManagerModule
        ];
      };
  };
}
