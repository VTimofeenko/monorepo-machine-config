let
  serviceName = "filedump";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./. + "/${serviceName}.nix";

  dashboard = {
    category = "Home";
    links = [
      {
        icon = "filebrowser";
        name = "Filedump";
      }
    ];
  };

  ingress =
    let
      port = 80;
    in
    {
      impl = import ./non-functional/firewall.nix { inherit port serviceName; };
      sslProxyConfig = import ./non-functional/ssl.nix { inherit port serviceName; };
    };

  # monitoring # TODO: implement
  # logging # TODO: implement
  backups = false; # Stateless
  storage = false; # Stateless
}
