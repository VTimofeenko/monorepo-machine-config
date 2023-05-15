{ pkgs, config, lib, ... }:
let
  eww-scripts = import ./scripts.nix pkgs;
  eww-yuck =
    ''
      (defwindow bar
              :monitor 0
              :geometry (geometry
                                  :width "100%"
                                  :height "1%"
                                  :anchor "top center"
                          )
              :exclusive true	
              :stacking "fg"
              (button :class "tray" :halign "end" "''${time}")
              (workspaces :halign "start")
      )

      (defpoll time :interval "20s"
          `date +" %b %d %R"`)
            
      (deflisten workspaces :initial "[]" "bash ${eww-scripts.get-workspaces}")
        (deflisten current_workspace :initial "1" "bash ${eww-scripts.get-active-workspace}")
        (defwidget workspaces []
          (eventbox :onscroll "bash ${eww-scripts.change-active-workspace} {} ''${current_workspace}" :class "workspaces-widget"
            (box :space-evenly true
              (label :text "''${workspaces}''${current_workspace}" :visible false)
              (for workspace in workspaces
                (eventbox :onclick "hyprctl dispatch workspace ''${workspace.id}"
                  (box :class "workspace-entry ''${workspace.id == current_workspace ? "current" : ""} ''${workspace.windows > 0 ? "occupied" : "empty"}"
                    (label :text "''${workspace.id}")
                    )
                  )
                )
              )
            )
          )

    '';
  inherit (import ./css.nix) eww-scss;
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
