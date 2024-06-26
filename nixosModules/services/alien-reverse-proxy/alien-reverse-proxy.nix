{ config, lib, ... }:
let
  inherit (config) my-data;
  inherit (lib.homelab) getServiceConfig getSrvSecret getSettings;
  inherit (lib) mapAttrs' nameValuePair;

  srvName = "alien-reverse-proxy";
  srvCfg = getServiceConfig srvName;
in
{
  age.secrets."ssl-cert" = {
    file = getSrvSecret "ssl-terminator" "cert";
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };
  age.secrets."ssl-key" = {
    file = getSrvSecret "ssl-terminator" "private-key";
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    # Produces an attrset of proxied domains with some standard nginx settings
    virtualHosts = mapAttrs' (
      name: value:
      nameValuePair "${name}.${getSettings.publicDomainName}" {
        forceSSL = true;
        sslCertificate = config.age.secrets."ssl-cert".path;
        sslCertificateKey = config.age.secrets."ssl-key".path;
        locations."/" = {
          proxyPass = "https://${value.hostName}:${toString value.port}";
          proxyWebsockets = true;
          extraConfig =
            # Allow human IPs, deny all
            lib.concatMapStringsSep "\n" (x: "allow ${x};") my-data.lib.humanIPs
            + ''
              deny all;
            '';
        };
      }
    ) srvCfg.proxyTargets;
  };
}
