{ lib, ... }:
{
  services.prometheus = {
    enable = true;
    retentionTime = "120d";
  };

  imports = [
    ./synology
    ./service-scraping
  ]
  ++ lib.localLib.mkImportsFromDir ./functional;
}
