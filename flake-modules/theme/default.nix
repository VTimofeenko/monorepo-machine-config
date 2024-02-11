# Flake module that produces NixOS and Home-manager modules with my theme
{ self, lib, ... }:
let
  module = import ./module.nix;
in
{
  flake = {
    nixosModules.my-theme = {
      imports = [
        self.inputs.base16.nixosModule
        module
      ];
    };
    homeManagerModules.my-theme = {
      imports = [
        self.inputs.base16.homeManagerModule
        module
      ];
    };

    data.my-colortheme =
      (lib.evalModules {
        modules = [
          { _module.check = false; }
          module
        ];
        specialArgs = {
          inherit lib;
          pkgs = self.inputs.nixpkgs-unstable.legacyPackages.x86_64-linux; # TODO: need a better way to pass pkgs here
        };
      }).config.my-colortheme;
  };
}
