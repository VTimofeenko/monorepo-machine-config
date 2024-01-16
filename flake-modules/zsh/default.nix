# Flake module that exposes my zsh config as a home manager and NixOS modules
_:
{
  # TODO: fzf ignore lock files for completion unless it's the only option
  flake = {
    nixosModules.zsh = import ./nixosModule.nix;
    homeManagerModules.zsh = import ./hmModule.nix;
  };
}
