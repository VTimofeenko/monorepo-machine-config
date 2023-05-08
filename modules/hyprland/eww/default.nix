{ pkgs, config, lib, ... }:
let
  eww-yuck =
    ''
        (defwindow example
                 :monitor 0
                 :geometry (geometry
                                     :width "100%"
                                     :height "1%"
                                     :anchor "top center"
                           )
                 :exclusive true	
                 :stacking "fg"
                 (button :class "tray" :halign "end" "''${time}")
        )

        (defpoll time :interval "20s"
      	`date +" %b %d %R"`)
    '';


  eww-scss =
    ''
    '';
in
{
  # Generating the module dynamically => not using home manager module
  home.packages = [ pkgs.eww-wayland ];
  xdg.configFile =
    {
      "eww/eww.yuck".text = eww-yuck;
      "eww/eww.scss".text = eww-scss;
    };
}
