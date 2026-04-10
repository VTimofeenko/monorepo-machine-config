{ lib, serviceName, ... }:
{
  module = ./docspell.nix;

  endpoints = {
    web = {
      port = 7880;
      protocol = "https";
    };
    filemanager = {
      port = 8002;
      protocol = "https";
    };
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  observability = { }; # TODO: implement a probe

  dashboard = {
    category = "Home";
    links = [
      {
        description = "Document storage";
        icon = "docspell";
        name = "Docspell";
      }
      {
        description = "Document dropbox";
        icon = "files";
        name = "Docspell dropbox";
        absoluteURL = "https://${lib.homelab.getServiceFqdn serviceName}/app/upload/${(lib.homelab.getServiceConfig serviceName).watchDirId}";
      }
    ];
  };
}
