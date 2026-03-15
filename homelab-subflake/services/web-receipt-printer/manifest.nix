serviceName: {
  module = ./web-receipt-printer.nix;

  endpoints.web = {
    port = 5000;
    protocol = "https";
  };

  # SSL proxy metadata
  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; port = 5000; };

  dashboard = {
    category = "Home";
    links = [
      {
        name = "Receipt printer";
        description = "Receipt printer";
        icon = "printer";
      }
    ];
  };

  documentation = ./README.md;
}
