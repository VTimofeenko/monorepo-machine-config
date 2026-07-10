/**
  Oxygen-specific network config.
*/
{ lib, ... }:
{
  imports = [ ];

  networking = {

    wireless.enable = lib.mkForce false;

    inherit ((lib.homelab.getNetwork "lan").settings) defaultGateway;
  };
}
