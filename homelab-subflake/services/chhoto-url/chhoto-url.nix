{ lib, ... }:
{
  services.chhoto-url = {
    enable = true;
    settings = {
      site_url = "https://${lib.homelab.getServiceFqdn "chhoto-url"}";
      # Printed QR codes are forever; keep targets editable
      redirect_method = "TEMPORARY";
      cache_control_header = "no-cache, private";
      # Uppercase slugs keep the QR payload in alphanumeric mode
      allow_capital_letters = true;
    };
  };
}
