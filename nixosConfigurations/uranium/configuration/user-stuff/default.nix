let
  systemImports = [ ];
  userImports = [
    ./desktop-environment.nix
    ./kanshi.nix
  ];
in
{
  imports = systemImports;

  home-manager.users.spacecadet.imports = userImports;
}
