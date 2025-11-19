{ lib, config, ... }:
{
  services.nginx.virtualHosts.${"healthchecks" |> lib.homelab.getServiceFqdn} = {
    # Disable OAuth on ping and metrics paths
    locations."/ping" = {
      proxyPass = "$srv_upstream";
      extraConfig = ''auth_request off;'';
    };

    # Reimplements the metrics location generation logic
    locations."~ /metrics/" = {
      proxyPass = "$srv_upstream";
      extraConfig = ''
        auth_request off;
      ''
      + config.services.nginx.virtualHosts.${
        "healthchecks" |> lib.homelab.getServiceFqdn
      }.locations.${(lib.homelab.getServiceConfig "healthchecks").metricsURL}.extraConfig;
    };
  };
}
