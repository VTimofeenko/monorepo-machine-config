# [[file:../../new_project.org::*Public firewall][Public firewall:1]]
{ lib, ... }:
{
  networking.firewall.allowedTCPPorts = lib.mkForce [ ];
  networking.firewall.allowedTCPPortRanges = lib.mkForce [ ];
  networking.firewall.allowedUDPPorts = lib.mkForce [ ];
  networking.firewall.allowedUDPPortRanges = lib.mkForce [ ];
}
# Public firewall:1 ends here
