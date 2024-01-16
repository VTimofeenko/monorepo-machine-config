# Flake module that exposes my zsh config as a home manager and NixOS modules
_:
{
  # TODO: fzf ignore lock files for completion unless it's the only option
  flake = {
    nixosModules.zsh = import ./nixosModule.nix;
    # System-wide settings that may needed if using the home-manager module
    nixosModules.zshHMCompanionModule = {
      environment.pathsToLink = [ "/share/zsh" ];
    };
    homeManagerModules.zsh = import ./hmModule.nix;
  };
}
