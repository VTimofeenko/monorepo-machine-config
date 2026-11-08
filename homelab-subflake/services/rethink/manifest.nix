{ lib, serviceName, ... }:
{
  module = ./rethink.nix;

  srvLib = import ./srv-lib.nix { inherit lib; };

  # Only the management UI goes through the central SSL proxy. Appliance-facing
  # TLS is terminated on this host, see ./rethink.nix.
  endpoints.web = {
    port = 44401;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  firewall = ./non-functional/firewall.nix;

  dashboard = {
    category = "Home";
    links = [
      {
        name = "rethink";
        icon = "mqtt";
        description = "Local LG ThinQ cloud";
      }
    ];
  };
}
