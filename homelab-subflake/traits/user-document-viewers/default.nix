{ pkgs, ... }:
{
  home-manager.users.spacecadet = {
    imports = [
      ./zathura.nix
      ./swayimg.nix
      ./office.nix
    ];
    home.packages = [ pkgs.gthumb ];
  };
}
