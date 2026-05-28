{ pkgs, lib, ... }:
{
  imports = [ ./lock.nix ];

  xdg.configFile."niri/config.kdl" = {
    source = pkgs.replaceVars ./config.kdl {
      kitty = lib.getExe pkgs.kitty;
      centerpiece = lib.getExe pkgs.centerpiece;
      fuzzel = lib.getExe pkgs.fuzzel;
      grimblast = lib.getExe pkgs.grimblast;
      swayosdClient = lib.getExe' pkgs.swayosd "swayosd-client";
      playerctl = lib.getExe pkgs.playerctl;
    };
    force = true;
  };

  services.swayosd.enable = true;

  programs.kitty.enable = true;
  services.mako.enable = true;
  services.polkit-gnome.enable = true;
  home.packages = with pkgs; [ swaybg ];
}
