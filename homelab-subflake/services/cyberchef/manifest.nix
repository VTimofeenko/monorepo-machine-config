{ lib, serviceName, ... }:
{
  module = ./cyberchef.nix;

  endpoints.web = {
    port = 80;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; port = 80; };

  dashboard = {
    category = "Dev";
    links = [
      {
        icon = "cyberchef";
        name = "Cyberchef";
      }
    ];
  };

  documentation = ./README.md;
}
