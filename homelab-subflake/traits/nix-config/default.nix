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

    settings = {
      connect-timeout = 5;
      download-buffer-size = 1048576000; # 1GB
      warn-dirty = false;
    };

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
