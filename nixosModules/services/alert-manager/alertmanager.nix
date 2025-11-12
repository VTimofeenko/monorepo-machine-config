{ lib, ... }:
{
  services.prometheus.alertmanager.enable = true;
  imports = lib.localLib.mkImportsFromDir ./functional;
}
