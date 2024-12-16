let
  systemImports = [ ];
  userImports = [
    ./desktop-environment.nix
  ];
in
{
  imports = systemImports;

  home-manager.users.spacecadet.imports = userImports;
}
