{
  /**
    Produces a module for my default SSL virtual host.

    Implementation notes:
    I am not necessarily happy about binding `config` and `lib` this way.
    However, this allows the caller code to be very simple and not bother about
    importing the resulting module.
  */
  mkStandardProxyVHost =
    {
      serviceName,
      port,
      config,
      lib,
      extraConfig ? "", # As default services.nginx.virtualHosts.<name>.extraConfig
    }:
    {
      services.nginx.virtualHosts."${serviceName |> lib.homelab.getServiceFqdn}" = {
        forceSSL = true;
        inherit (config.services.homelab.ssl-proxy) listenAddresses;
        sslCertificate = config.age.secrets."ssl-cert".path;
        sslCertificateKey = config.age.secrets."ssl-key".path;
        locations."/" = {
          proxyPass = "http://${serviceName |> lib.homelab.getServiceInnerIP}:${port |> toString}";
          proxyWebsockets = true;
        };
        inherit extraConfig;
      };
    };
}
