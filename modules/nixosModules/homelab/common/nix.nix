# Nix the package manager config
{ pkgs, self, ... }:
{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  system.nixos.label = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
}
