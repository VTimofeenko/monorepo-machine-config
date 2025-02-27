rec {
  default = [
    module
    ingress.impl
  ];
  module = ./docspell.nix;

  dashboard = {
    category = "Home";
    links = [
      {
        description = "Document storage";
        icon = "docspell";
        name = "Docspell";
      }
    ];
  };
  ingress = {
    impl = ./non-functional/firewall.nix;
    sslProxyConfig = ./non-functional/ssl.nix;
  };
}
