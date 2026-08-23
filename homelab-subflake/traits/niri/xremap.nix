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
}
