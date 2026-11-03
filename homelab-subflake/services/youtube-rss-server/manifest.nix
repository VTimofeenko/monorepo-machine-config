{ serviceName, ... }:
{
  module = ./youtube-rss-server.nix;

  endpoints.web = {
    port = 8010;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  # No auth of its own and every miss spends YouTube API quota
  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  roamNodes = [
    "5f5a84e7-096f-4875-9c98-e3d989f1994b" # YouTube RSS server
    "9119829c-2fd5-4931-8ca9-346eacf2bc15" # Miniflux
  ];
}
