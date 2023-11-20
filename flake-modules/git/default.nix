# Flake module that exposes my git configuration as a module
# { self, lib }:
_:
{
  flake = {
    # nixosModules.git =  # TODO: needed?
    homeManagerModules.git = import ./hmModule.nix;
  };
}
