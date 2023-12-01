# [[file:../../../../new_project.org::*Neptunium network][Neptunium network:1]]
{ lib, ... }:
{
  networking = {
    hostName = "neptunium";
    wireless.enable = lib.mkForce false;
    useDHCP = lib.mkForce true;
    firewall.enable = lib.mkForce false;
  };
}
# Neptunium network:1 ends here
