/**
  niri-specific xremap wiring.

  Reuses the shared keymaps from `../base-wayland-environment/xremap`, but
  niri isn't wlroots-based (unlike Hyprland) so it needs xremap's
  `withNiri` integration instead of `withWlroots`, and can't share that
  trait's `default.nix` wholesale.
*/
{ inputs, ... }:
{
  imports = [
    inputs.xremap-flake.nixosModules.default
    ../base-wayland-environment/xremap/shortcuts.nix
    ../base-wayland-environment/xremap/app-jumps.nix
  ];

  services.xremap = {
    enable = true;
    withNiri = true;
    userName = "spacecadet";
    serviceMode = "user";
    watch = true;
  };

  # The xremap-flake NixOS module's user-service path (unlike its own
  # home-manager module) only sets `after`/`wantedBy` on graphical-session.target,
  # not `partOf` -- so stopping the target never stops xremap.service. It's
  # left running with a stale NIRI_SOCKET across logins, and re-starting the
  # target on relogin is a no-op since xremap.service never went inactive.
  systemd.user.services.xremap.partOf = [ "graphical-session.target" ];
}
