# [[file:../../new_project.org::*Nix-the-package-manager config][Nix-the-package-manager config:2]]
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
  };
}
# Nix-the-package-manager config:2 ends here
