{
  config,
  lib,
  self,
  ...
}:
let
  watchDir = {
    port = 8002;
    path = "watch-dir";
  };
  serviceName = "docspell";
in
{
  imports =
    [
      (self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
        serviceName = "docspell";
        port = 7880;
        # Docspell deals with big files
        extraConfig = ''
          client_max_body_size 100M;
        '';
        onlyHumans = true;
        inherit config lib;
      })
    ]
    ++ (
      [
        watchDir
      ]
      |> map (it: {
        services.nginx.virtualHosts."${
          serviceName |> lib.homelab.getServiceFqdn
        }".locations."/${it.path}/" =
          {
            proxyPass = "http://${
              serviceName |> lib.homelab.getServiceInnerIP
            }:${it.port |> toString}/${it.path}/";
          };
      })
    );
}
