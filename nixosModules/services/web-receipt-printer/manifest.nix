let
  serviceName = "web-receipt-printer";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./. + "/${serviceName}.nix";

  ingress = rec {
    port = 5000;
    impl = import ./non-functional/firewall.nix { inherit port; };
    sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
  };

  dashboard = {
    category = "Home";
    links = [
      {
        description = "Receipt printer";
        icon = "printer";
        name = "Receipt printer";
      }
    ];
  };

  storage = false;
}
