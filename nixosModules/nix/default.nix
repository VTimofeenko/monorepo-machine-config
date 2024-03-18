/**
  Nix-the-package-manager configuration.

  Pins a couple of commonly used flake registry points as "ns" for stable and "nu" for unstable. This is useful to prevent extra nixpkgs downloads when running one-off commands in `nix run`

  Development packages will be pulled into the package set. The set (environment.systemPackages or home.packages) is picked depending on whether this module is run in home-manager or NixOS context.
*/
{
  nixpkgs-stable,
  nixpkgs-unstable,
  inHomeManager ? false,
}:
{ pkgs, config, ... }:
let
  outer = if inHomeManager then "home" else "environment";
  inner = if inHomeManager then "packages" else "systemPackages";
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
    registry = {
      ns.flake = nixpkgs-stable;
      nu.flake = nixpkgs-unstable;
    };
  };

  ${outer}.${inner} = builtins.attrValues { inherit (pkgs) nix-melt nix-top; };
}
