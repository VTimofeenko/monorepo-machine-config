{
  imports = [
    ./greeter.nix
    ./niri-base.nix
    ./xremap.nix
    ./xdg-portal.nix
  ];

  home-manager.users.spacecadet.imports = [
    ./hm/default.nix
  ];
}
