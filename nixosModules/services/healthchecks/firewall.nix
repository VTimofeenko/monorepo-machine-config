# NOTE: This should be later used as an example "client net" generating firewall function
{ lib, ... }:
let
  srvName = "healthchecks";
  inherit (lib.homelab) getServiceConfig;
in
{
  networking.firewall.interfaces."client".allowedTCPPorts = [ (getServiceConfig srvName).proxyPort ];
}
