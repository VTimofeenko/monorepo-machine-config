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
{ serviceName, ... }:
{
  module = ./your-spotify.nix;

  endpoints = {
    web = {
      port = 80; # nginx frontend
      protocol = "https";
    };
    api = {
      port = 8081; # backend API
      protocol = "tcp";
    };
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = { }; # TODO: implement 200 probe only

  # Backups disabled — TODO
  # backups = { ... };

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
}
