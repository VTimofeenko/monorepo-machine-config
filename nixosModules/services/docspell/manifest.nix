let
  serviceName = "docspell";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./docspell.nix;

  observability = {
    enable = true;
    alerts = rec {
      enable = true;
      grafanaImpl = if enable then import ./non-functional/alerts.nix { inherit serviceName; } else { };
    };
  };
  dashboard =
    { lib, ... }:
    {
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
          absoluteURL = "https://${lib.homelab.getServiceFqdn serviceName}/app/upload/${(lib.homelab.getServiceConfig "docspell").watchDirId}";
        }
      ];
    };

  ingress = {
    impl = ./non-functional/firewall.nix;
    sslProxyConfig = ./non-functional/ssl.nix;
  };
}
