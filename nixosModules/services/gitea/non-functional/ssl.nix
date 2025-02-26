{
  config,
  lib,
  self,
  ...
}:
let
  serviceName = "gitea";
in
{
  # Standard SSL proxy for web interface
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
      port = config.services.gitea.settings.server.HTTP_PORT;
      inherit config lib serviceName;
    })
  ];

  # Add heatmap proxy token
  services.nginx.virtualHosts.${lib.homelab.getServiceFqdn serviceName}.locations."/api/v1/users/spacecadet/heatmap" =
    {
      proxyPass = "http://localhost:${toString config.services.gitea.settings.server.HTTP_PORT}/api/v1/users/spacecadet/heatmap";
      extraConfig = ''
        proxy_set_header Authorization "${(lib.homelab.getServiceConfig serviceName).heatmapToken}";
      '';
    };

  # Proxy ssh
  services.nginx.streamConfig = ''
    server {
      ${
        config.services.homelab.ssl-proxy.listenAddresses
        |> map (it: "listen ${it}:22;")
        |> lib.concatLines
      }
      proxy_pass ${serviceName |> lib.homelab.getServiceInnerIP}:22;
    }
  '';
}
