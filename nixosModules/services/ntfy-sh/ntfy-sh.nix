{ lib, ... }:
{
  services.ntfy-sh = {
    enable = true;
    settings.base-url = "https://${lib.homelab.getServiceFqdn "ntfy-sh"}";
  };
}
