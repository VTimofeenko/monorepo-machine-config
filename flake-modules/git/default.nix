# Flake module that exposes my git configuration as a module
{ conventional-commit-helper, ... }:
{
  flake.homeManagerModules.git = import ./home-manager { inherit conventional-commit-helper; };
}
