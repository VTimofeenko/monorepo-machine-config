{ ... }:
{
  services.lubelogger.enable = true;

  imports = [
    ./non-functional/sso.nix
  ];
}
