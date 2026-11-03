/**
  Configures nix-the-package manager.
*/
{
  config,
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (inputs) nixpkgs nixpkgs-unstable;
in
{
  nix = {
    extraOptions = "experimental-features = nix-command flakes pipe-operators";

    # Higher download buffer size
    settings.download-buffer-size = 1048576000; # 1GB

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
      ns.flake = nixpkgs;
      nu.flake = nixpkgs-unstable;
    };
  };
  # `<rev>[-dirty]-<nixpkgs date>.<nixpkgs rev>`: lands in the switch's
  # journald line (`…-nixos-system-<host>-<label>`), so deployments carry nixpkgs
  system.nixos.label =
    toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown")
    + "-"
    + lib.removePrefix "." config.system.nixos.versionSuffix;
}
