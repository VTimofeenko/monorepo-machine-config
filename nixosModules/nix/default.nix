{ nixpkgs-stable, nixpkgs-unstable }:
{ pkgs, ... }:
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

  environment.systemPackages = builtins.attrValues { inherit (pkgs) nix-melt nix-top; };
}
