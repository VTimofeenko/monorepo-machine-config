# [[file:../../new_project.org::*Desktop environment][Desktop environment:1]]
{ pkgs, lib, config, ... }:
{
  imports = [
    ./greeter.nix # (ref:greeter-import)
    ./notifications.nix # (ref:notifications-de-import)
    ./eww
    # ./wofi  # TODO: 23.05
    ../hyprland/system.nix # (ref:hyprland-system-import)
  ];
  home-manager.users.spacecadet = { pkgs, ... }: {
    imports = [
      ../hyprland/user.nix # (ref:hyprland-user-import)
    ];
  };
}
# Desktop environment:1 ends here
