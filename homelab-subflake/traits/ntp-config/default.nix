{ lib, ... }:
{
  time.timeZone = "America/Los_Angeles";
  # TODO: add some fallbacks or just rely on DHCP handing this out
  services.timesyncd.servers = lib.mkForce [ (lib.homelab.getServiceFqdn "ntp") ];
}
