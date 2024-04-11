/**
  Nix-the-package-manager configuration.

  Pins a couple of commonly used flake registry points as "ns" for stable and "nu" for unstable. This is useful to prevent extra nixpkgs downloads when running one-off commands in `nix run`

  Development packages will be pulled into the package set. The set (environment.systemPackages or home.packages) is picked depending on whether this module is run in home-manager or NixOS context.
*/

# TODO: move to flake-modules so 'inHomeManager' is not exposed to caller
{
  nixpkgs-stable,
  nixpkgs-unstable,
  inHomeManager ? false,
  inputs,
}:
{
  pkgs,
  config,
  lib,
  ...
}:
let
  outer = if inHomeManager then "home" else "environment";
  inner = if inHomeManager then "packages" else "systemPackages";

  inherit (lib) mapAttrs' nameValuePair filterAttrs;
in
{
  # Allow unfree packages across the board
  nixpkgs.config.allowUnfree = true;
  nix = {
    extraOptions = ''
      # Quicker timeout for inaccessible binary caches
      connect-timeout = 5
      # Enable flakes
      experimental-features = nix-command flakes
      # Do not warn on dirty git repo
      warn-dirty = false
      # Automatically optimize store
      auto-optimise-store = true
    '';
    registry =
      {
        ns.flake = nixpkgs-stable;
        nu.flake = nixpkgs-unstable;
      }
      # Since my systems have a single global flake that governs them, I can pin all its inputs in the local registry for fast reuse in flake.lock.
      // (mapAttrs' (a: v: nameValuePair ("pinned-" + a) { flake = v; }) (
        filterAttrs (_: v: (v ? _type && v._type == "flake")) inputs # Filter only flakes in inputs
      ));
  };

  ${outer}.${inner} = builtins.attrValues { inherit (pkgs) nix-melt nix-top; };
}
