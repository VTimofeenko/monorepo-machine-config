{ lib, ... }:
{
  services.nginx.virtualHosts.${"healthchecks" |> lib.homelab.getServiceFqdn} = {
    # Disable OAuth on ping and metrics paths
    locations."/ping" = {
      proxyPass = "$srv_upstream";
      extraConfig = ''auth_request off;'';
    };

    locations."~ /metrics/" = {
      proxyPass = "$srv_upstream";
      extraConfig = ''auth_request off;'';
    };
  };
}
