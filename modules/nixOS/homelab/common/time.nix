# Time-related settings
{ lib, ... }:
{
  time.timeZone = "America/Los_Angeles";
  services.timesyncd.servers = lib.mkForce [ (lib.homelab.getServiceFqdn "ntp") ];
}
