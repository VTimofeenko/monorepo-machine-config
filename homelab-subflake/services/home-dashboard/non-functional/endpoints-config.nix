endpoints: { lib, ... }:
{
  services.homepage-dashboard.allowedHosts = lib.homelab.getServiceFqdn "home-dashboard";
}
