# [[file:../../new_project.org::*Desktop environment][Desktop environment:1]]
{
  selfPkgs,
  selfHMModules,
  selfModules,
  ...
}:
{
  imports = [
    # ./greeter.nix # (ref:greeter-import)
    # ../hyprland/system.nix # (ref:hyprland-system-import)
    ./xremap
    selfModules.de
  ];
  home-manager.extraSpecialArgs = {
    inherit selfPkgs;
    inherit selfHMModules;
  };
  home-manager.users.spacecadet =
    { pkgs, ... }:
    {
      imports = [
        # ../hyprland/user.nix # (ref:hyprland-user-import)
        # ./eww # (ref:eww-import)
        # ./notifications.nix # (ref:notifications-de-import)
        # ./wallpaper.nix
        # ./vnc
        # hyprland.homeManagerModules.default
        selfHMModules.de
        selfHMModules.hyprland-helpers
      ];
      home.packages = builtins.attrValues { inherit (pkgs) wl-clipboard; };

      services.hyprland-helpers = {
        enable = true;
        target = "xdg-desktop-autostart.target";
      };
    };
}
# Desktop environment:1 ends here
