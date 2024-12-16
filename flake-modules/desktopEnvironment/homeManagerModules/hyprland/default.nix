{ lib, ... }: {
  imports = [
    # ./input.nix
    # ./general.nix
    # ./theme.nix
    # ./decoration.nix
    # ./animations.nix
    # ./layouts.nix
    # ./windowRules.nix
    # ./gestures.nix
    ./binds
    # ./pinentry.nix
  ];
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.systemd.enable = lib.mkForce false;

  services.swaync.enable = true;
}
