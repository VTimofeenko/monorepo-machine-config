{ serviceName, ... }:
{
  module = ./chhoto-url.nix;

  endpoints.web = {
    port = 4567;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  backups = {
    # DynamicUser: /var/lib/chhoto-url is a symlink into /var/lib/private
    paths = [ "/var/lib/private/chhoto-url" ];
  };

  dashboard = {
    category = "Home";
    links = [
      {
        description = "Short links for QR codes";
        icon = "chhoto-url";
        name = "Chhoto URL";
      }
    ];
  };

  documentation = ./README.md;
}
