rec {
  default = [
    module
    ingress.impl
  ];
  module = ./tt-rss.nix;

  ingress = {
    impl = ./non-functional/firewall.nix;
    sslProxyConfig = ./non-functional/ssl.nix;
  };

  dashboard = {
    category = "Media";
    links = [
      {
        description = "Shared RSS";
        icon = "tinytinyrss";
        name = "TT-RSS";
      }
    ];
  };
}
