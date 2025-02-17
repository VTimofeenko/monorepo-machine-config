{ lib, ... }:
{
  services.homepage-dashboard.services = [
    {
      Maintenance = [
        {
          Dashboard.widget = {
            type = "iframe";
            src = "https://${lib.homelab.getServiceFqdn "filedump"}/home_maint.html";
          };
        }
      ];
    }
  ];
}
