endpoints: { lib, ... }:
let
  fqdn = "your-spotify" |> lib.homelab.getServiceFqdn;
  clientEndpoint = "https://${fqdn}";
in
{
  services.your_spotify.settings = {
    PORT = endpoints.api.port;
    CLIENT_ENDPOINT = clientEndpoint;
    API_ENDPOINT = clientEndpoint + "/api";
  };
  services.your_spotify.nginxVirtualHost = fqdn;

  services.nginx.virtualHosts.${fqdn} = {
    extraConfig = ''
      client_max_body_size 500M;
    '';
    locations."/api/" = {
      proxyPass = "http://127.0.0.1:${endpoints.api.port |> toString}/";
      extraConfig = ''
        proxy_set_header X-Script-Name /api;
        proxy_pass_header Authorization;
      '';
    };
  };
}
