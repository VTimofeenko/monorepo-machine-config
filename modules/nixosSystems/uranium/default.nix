# [[file:../../../new_project.org::*Uranium specific system][Uranium specific system:1]]
{ pkgs
, lib
, config
, my-sway-config
, my-doom-config
, ...
}@inputs:
{
  imports = [
    my-sway-config.nixosModules.system
    inputs.wg-namespace-flake.nixosModules.default
    ../../network/lan-wifi.nix
    # TODO: add optional phone network here commented

    ./hardware # (ref:uranium-hw-import)
  ];
  home-manager.users.spacecadet = { ... }: {
    imports = [
      my-sway-config.nixosModules.default
    ];
    wayland.windowManager.sway.config = {
      # Restore non-vm modifier
      modifier = "Mod4";
      # Output configuration
      output = {
        "eDP-1" = { "scale" = "1"; };
      };
    };
    vt-sway.enableBrightness = true;
  };
}
# Uranium specific system:1 ends here
