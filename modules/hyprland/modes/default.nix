# [[file:../../../new_project.org::*Hyprland modes][Hyprland modes:1]]
{ lib, ... }:
let
  /* Type: mkModeBinding :: (str -> str -> str) -> module */
  mkModeBinding = modeEnterKeyBind: modeName: modeBinds: {
    wayland.windowManager.hyprland.extraConfig =
      lib.mkAfter
        ''
          bind = ${modeEnterKeyBind},submap,${modeName}
          submap = ${modeName}

          ${modeBinds}


          # use escape to go back to global map
          bind=,escape,submap,reset
          submap = reset
        '';
  };
in
{
  # A novel and elegant importApply!
  imports = builtins.map
    (module: (import module mkModeBinding))
    [
      ./sound_ctl.nix
      ./resize_ctl.nix
      # ./workspace_edit.nix # TODO
      ./power_ctl.nix
      ./pass-helpers.nix
    ];
}
# Hyprland modes:1 ends here
