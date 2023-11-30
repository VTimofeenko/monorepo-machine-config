# [[file:../../new_project.org::*Desktop environment][Desktop environment:1]]
{ pyprland, selfPkgs, selfHMModules, hyprland, ... }:
{
  imports = [
    ./greeter.nix # (ref:greeter-import)
    # ./wofi  # TODO: 23.05
    ../hyprland/system.nix # (ref:hyprland-system-import)
    ./xremap
  ];
  home-manager.extraSpecialArgs = {
    inherit pyprland;
    inherit selfPkgs;
    inherit selfHMModules;
  };
  home-manager.users.spacecadet = { pkgs, ... }: {
    imports = [
      ../hyprland/user.nix # (ref:hyprland-user-import)
      ./eww # (ref:eww-import)
      ./notifications.nix # (ref:notifications-de-import)
      ./wallpaper.nix
      hyprland.homeManagerModules.default
    ];
    home.packages = builtins.attrValues {
      inherit (pkgs) wl-clipboard;
    };
  };
}
# Desktop environment:1 ends here
