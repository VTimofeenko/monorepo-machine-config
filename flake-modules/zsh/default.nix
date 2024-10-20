# Flake module that exposes my zsh config as a home manager and NixOS modules
_: {
  flake = {
    # FIXME: ideally my theme should be imported here, but multiple imports of same module are broken
    # https://github.com/NixOS/nix/issues/7270
    nixosModules.zsh = import ./modules/nixOS;
    homeManagerModules.zsh = import ./modules/homeManager;
  };
}
