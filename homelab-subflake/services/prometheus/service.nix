{ lib, ... }:
{
  services.prometheus = {
    enable = true;
    retentionTime = "120d";
    alertmanagers = [
      {
        static_configs = [
          { targets = [ "${lib.homelab.getServiceInnerIP "alert-manager"}:9093" ]; }
        ];
      }
    ];
  };

  imports = [
    ./synology
    ./service-scraping
  ]
  ++ lib.localLib.mkImportsFromDir ./functional;
}
