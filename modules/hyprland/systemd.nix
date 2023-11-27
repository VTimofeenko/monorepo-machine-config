# home-manager module that adds hyprland as a systemd unit and makes certain services bind to it
{ config, lib, ... }:
{
  systemd.user.services.hyprland-run = {
    Unit = {
      Description = "My hyprland wrapper that runs it in systemd";
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe config.wayland.windowManager.hyprland.package}";
    };
    # Install # NOTE: Run manually
  };
}
