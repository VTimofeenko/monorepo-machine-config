# [[file:../../new_project.org::*Public firewall][Public firewall:1]]
{ lib, ... }:
{
  networking = {
    firewall = {
      allowedTCPPorts = lib.mkForce [ ];
      allowedTCPPortRanges = lib.mkForce [ ];
      allowedUDPPorts = lib.mkForce [ ];
      allowedUDPPortRanges = lib.mkForce [ ];
    };
  };
}
# Public firewall:1 ends here
