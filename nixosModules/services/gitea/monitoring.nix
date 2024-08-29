# Configures monitoring for the service; allows monitoring access only from a specific host
{ lib, config, ... }:
let
  inherit (lib.homelab)
    getServiceConfig
    getServiceFqdn
    getService
    getHostIpInNetwork
    ;
  srvName = "gitea";

  prometheusIP = lib.pipe "prometheus" [
    getService
    (builtins.getAttr "onHost")
    (lib.flip getHostIpInNetwork "lan") # Request will be through LAN
  ];
in

{
  services.gitea.settings.metrics = {
    # Gotta be "ENABLED" IN ALL CAPS
    ENABLED = true;
    TOKEN = (getServiceConfig srvName).metricsToken;
  };

  # Allow /metrics only from specific hosts
  services.nginx.virtualHosts.${getServiceFqdn srvName}.locations."/metrics" = {
    proxyPass = "http://localhost:${toString config.services.gitea.settings.server.HTTP_PORT}/metrics";
    extraConfig = ''
      allow ${prometheusIP};
      deny all;
    '';
  };
}
