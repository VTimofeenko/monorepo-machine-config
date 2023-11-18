# Flake module that exposes my zsh config as a home manager and NixOS modules
{ self, lib }:
{
  flake = {
    nixosModules.zsh = import ./nixosModule.nix { inherit self; };
    # System-wide settings that may needed if using the home-manager module
    nixosModules.zshHMCompanionModule = {
      environment.pathsToLink = [ "/share/zsh" ];
    };
    homeManagerModules.zsh = import ./hmModule.nix { inherit self; };
  };
}
