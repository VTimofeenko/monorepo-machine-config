{ lib, config, ... }:
let
  inherit (lib) pipe;
  inherit (lib.homelab) getServiceConfig;
  inherit (getServiceConfig "prometheus") exporters;
in
{
  networking.firewall.interfaces.monitoring.allowedTCPPorts = pipe exporters [
    (map (x: config.services.prometheus.exporters.${x}.port))
  ];
}
