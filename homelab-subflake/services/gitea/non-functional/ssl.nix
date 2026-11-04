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

  services.nginx.virtualHosts.${lib.homelab.getServiceFqdn serviceName}.locations = {
    # Add heatmap proxy token
    "/api/v1/users/spacecadet/heatmap" = {
      proxyPass = "$srv_upstream";
      extraConfig = ''
        proxy_set_header Authorization "${(lib.homelab.getServiceConfig serviceName).heatmapToken}";
      '';
    };

    # Anonymous source archive downloads (fetchFromGitea) despite REQUIRE_SIGNIN_VIEW
    # - token belongs to a bot user that only sees public repos
    "~ ^/[^/]+/[^/]+/archive/" = {
      proxyPass = "$srv_upstream";
      extraConfig = ''
        proxy_set_header Authorization "${(lib.homelab.getServiceConfig serviceName).archiveToken}";
      '';
    };
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
