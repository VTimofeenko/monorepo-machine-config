{ lib, ... }:
let
  prometheusIP = "prometheus" |> lib.homelab.getServiceHost |> lib.flip lib.homelab.getHostIpInNetwork "lan";
in
{
  services.nginx.virtualHosts.${"healthchecks" |> lib.homelab.getServiceFqdn} = {
    # Disable OAuth on ping and metrics paths
    locations."/ping" = {
      proxyPass = "$srv_upstream";
      extraConfig = ''auth_request off;'';
    };

    locations."~ /metrics/" = {
      proxyPass = "$srv_upstream";
      extraConfig = ''
        auth_request off;
        allow ${prometheusIP};
        deny all;
      '';
    };
  };
}
