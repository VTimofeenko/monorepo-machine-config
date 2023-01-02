{ pkgs, ... }:
{
  home-manager.users.spacecadet = { ... }: {
    home.packages = [ pkgs.calibre ];
  };
}
