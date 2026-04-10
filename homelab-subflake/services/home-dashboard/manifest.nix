{ serviceName, ... }:
{
  module = ./home-dashboard.nix;

  endpoints.web = {
    port = 8082;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = { }; # TODO: implement 200 probe and staleness probe for home tasks

  # No dashboard entry for the dashboard itself.
}
