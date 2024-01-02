/* Flake module that produces NixOS and Home-manager modules with my theme */
{ self, lib, ... }:
let
  module = import ./module.nix { inherit lib; };
in
{
  flake = {
    nixosModules.my-theme = module // { imports = [ self.inputs.base16.nixosModule ]; };
    homeManagerModules.my-theme = module // { imports = [ self.inputs.base16.homeManagerModule ]; };
  };
}
