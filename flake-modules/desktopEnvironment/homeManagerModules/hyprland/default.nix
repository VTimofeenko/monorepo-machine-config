{ lib, osConfig, ... }:
{
  imports = [
    # ./input.nix
    # ./general.nix
    # ./theme.nix
    # ./decoration.nix
    # ./animations.nix
    # ./layouts.nix
    ./windowRules.nix
    # ./gestures.nix
    ./lock.nix
    ./launcher.nix
    ./binds
    ./monitors.nix
    # ./pinentry.nix
    ./terminal.nix
    ./workspaces.nix
    ./language.nix
  ];
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.systemd.enable =
    assert lib.assertMsg osConfig.programs.uwsm.enable
      "uwsm should be enabled for this setting to work as exxpected";
    (lib.mkForce false);

  services.swaync.enable = true;
}
