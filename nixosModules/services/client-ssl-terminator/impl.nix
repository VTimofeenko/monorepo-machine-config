# Nginx configuration for proxying services in client network
{ lib, config, ... }:
let
  # srvName = "client-ssl-terminator";

  inherit (lib.homelab) getSrvSecret getHostInNetwork;
  inherit (lib)
    mapAttrs'
    mapAttrs
    nameValuePair
    pipe
    filterAttrs
    ;
  inherit (config) my-data;
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
    virtualHosts = pipe my-data.services.all [
      (filterAttrs (_: v: v ? networkAccess && v.networkAccess == [ "client" ])) # Get the services to proxy
      (mapAttrs (
        _: v: {
          inherit (v) fqdn onHost;
          inherit (v.settings) proxyPort;
        }
      )) # Transform only to keep relevant keys
      # TODO: Fix the DNS resolution of hosts in client network, remove this ip replacement
      (mapAttrs (
        _: v: {
          inherit (v) proxyPort fqdn;
          onHost = (getHostInNetwork v.onHost "client").ipAddress;
        }
      )) # Transform only to keep relevant keys
      (mapAttrs' (
        _: value:
        nameValuePair value.fqdn {
          forceSSL = true;
          sslCertificate = config.age.secrets."ssl-cert".path;
          sslCertificateKey = config.age.secrets."ssl-key".path;
          locations."/" = {
            proxyPass = "http://${value.onHost}:${toString value.proxyPort}";
            proxyWebsockets = true;
          };
        }
      ))
      # TODO: custom per-service overrides should go here
    ];
  };
}
