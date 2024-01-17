/* Flake module that produces NixOS and Home-manager modules with my theme */
{ self, lib, ... }:
let
  module = import ./module.nix { inherit lib; };
in
{
  # TODO: add an attribute that prepends the "#" sign
  flake = {
    nixosModules.my-theme = module // { imports = [ self.inputs.base16.nixosModule ]; };
    homeManagerModules.my-theme = module // { imports = [ self.inputs.base16.homeManagerModule ]; };
  };
}
