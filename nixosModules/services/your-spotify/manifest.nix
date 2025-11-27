/**
  Upstream docs
  https://github.com/Yooooomi/your_spotify?tab=readme-ov-file#installation

  Call for two endpoints:
  - API_ENDPOINT
  - CLIENT_ENDPOINT

  CLIENT_ENDPOINT(port 3000) looks like it should be the domain
  (your-spotify.srv.vtimofeenko.com).

  API_ENDPOINT(port 8080) should be accessible to the user, but Nix docs
  suggest using a different domain.

  I will try to move the API_ENDPOINT to a sub path in nginx...
*/
let
  serviceName = "your-spotify";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./. + "/${serviceName}.nix";

  ingress =
    let
      port = 8081;
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port serviceName; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  dashboard = {
    category = "Media";
    links = [
      {
        description = "Spotify history exporter";
        icon = "your-spotify";
        name = "Your Spotify";
      }
    ];
  };
  observability = {
    enable = true;
    alerts = rec {
      enable = true;
      grafanaImpl = if enable then import ./non-functional/alerts.nix { inherit serviceName; } else { };
    };
  };
  backups = false; # TODO
}
