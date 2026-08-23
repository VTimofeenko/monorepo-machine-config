{
  imports = [
    ./greeter.nix
    ./niri-base.nix
    ./xremap.nix
  ];

  home-manager.users.spacecadet.imports = [
    ./hm/default.nix
  ];
}
