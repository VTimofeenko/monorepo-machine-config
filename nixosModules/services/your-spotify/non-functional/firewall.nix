{ serviceName, port }:
{
  lib,
  self,
  ...
}:
let
  fqdn = serviceName |> lib.homelab.getServiceFqdn;
  clientEndpoint = "https://${fqdn}";
in
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [
        port
        80 # This service uses nginx
      ];
    })
  ];
  services.your_spotify.settings = {
    PORT = port;
    CLIENT_ENDPOINT = clientEndpoint;
    API_ENDPOINT = clientEndpoint + "/api";
  };
  services.your_spotify.nginxVirtualHost = fqdn;

  services.nginx.virtualHosts.${fqdn} = {
    extraConfig = ''
      client_max_body_size 500M;
    '';
    locations."/api/" = {
      proxyPass = "http://127.0.0.1:${port |> toString}/";
      extraConfig = ''
        proxy_set_header X-Script-Name /api;
        proxy_pass_header Authorization;
      '';
    };
  };
}
