{
  imports = [
    ./greeter.nix
    ./niri-base.nix
  ];

  home-manager.users.spacecadet.imports = [
    ./hm/default.nix
  ];
}
