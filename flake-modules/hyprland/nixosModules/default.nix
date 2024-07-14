# System module that configures hyprland and adjacent packages.
_: {
  imports = [
    ./greeter.nix
    ./xdgPortal.nix
    ./hyprland.nix
    ./lock.nix
  ];
}
