{ pkgs, ... }:
{
  home-manager.users.spacecadet = {
    imports = [ ./mpv.nix ];

    home.packages = with pkgs; [
      pavucontrol
      blueman
      # Local image editing and organizing
      digikam
      exiftool
    ];
  };
}
