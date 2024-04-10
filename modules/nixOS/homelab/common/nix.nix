# Nix the package manager config
{
  pkgs,
  self,
  lib,
  ...
}:
let
  inherit (self.inputs) nixpkgs-stable nixpkgs-unstable;
in
{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = lib.mkForce [ "weekly" ];
    };
    registry = {
      ns.flake = nixpkgs-stable;
      nu.flake = nixpkgs-unstable;
    };
  };
  system.nixos.label = toString (
    self.shortRev or self.dirtyShortRev or self.lastModified or "unknown"
  );
}
