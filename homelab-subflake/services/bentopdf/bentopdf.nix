{ lib, ... }:
{
  services.bentopdf = {
    enable = true;
    domain = lib.homelab.getServiceFqdn "bentopdf";
    nginx.enable = true;
  };
}
