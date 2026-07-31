{ lib, ... }:
{
  services.homepage-dashboard = {
    services = [
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

    # Let the Maintenance group span the full row instead of sharing a
    # column with the other groups.
    settings.layout.Maintenance = {
      style = "row";
      columns = 1;
    };
  };
}
