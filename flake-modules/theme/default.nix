# Flake module that produces NixOS and Home-manager modules with my theme
{ self, ... }:
let
  module = import ./module.nix;
in
{
  # TODO: add an attribute that prepends the "#" sign
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
  };
}
