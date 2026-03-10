{
  imports = [
    # ./greeter
    # ./notifications
    # ./lock
    # Whatever else from current desktop env
    ./xremap
    ./xdg-portal.nix
    {
      home-manager.users.spacecadet.imports = [ ./wallpaper.nix ];
    }
  ];
}
