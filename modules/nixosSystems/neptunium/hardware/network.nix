# [[file:../../../../new_project.org::*Neptunium network][Neptunium network:1]]
{ config, pkgs, lib, ... }:
{
  networking.hostName = "neptunium";
  networking.wireless.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce true;
  networking.firewall.enable = lib.mkForce false;
}
# Neptunium network:1 ends here
