/**
  Oxygen-specific network config.
*/
{ lib, ... }:
{
  imports = [ ];

  networking = {

    wireless.enable = lib.mkForce false;

    defaultGateway.interface = "phy-lan"; # This may be needed by default...
  };
}
