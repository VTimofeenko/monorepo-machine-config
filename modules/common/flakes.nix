# From https://nixos.wiki/wiki/Flakes
{ pkgs, ... }: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
