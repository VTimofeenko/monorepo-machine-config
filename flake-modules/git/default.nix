/* Flake module that exposes my git configuration as a module */
_:
{
  flake.homeManagerModules.git = import ./hmModule.nix;
}
