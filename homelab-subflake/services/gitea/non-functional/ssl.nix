{
  serviceName,
  sshPort,
  webPort,
  ...
}:
{
  config,
  lib,
  self,
  ...
}:
{
  # Standard SSL proxy for web interface
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
      port = webPort;
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
        |> map (it: "listen ${it}:${sshPort |> toString};")
        |> lib.concatLines
      }
      proxy_pass ${serviceName |> lib.homelab.getServiceInnerIP}:${sshPort |> toString};
    }
  '';
}
