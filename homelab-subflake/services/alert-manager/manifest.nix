let
  serviceName = "alert-manager";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./alertmanager.nix;

  ingress =
    let
      servicePort = 9093;
    in
    {
      impl = ./non-functional/firewall.nix;
      sslProxyConfig = ./non-functional/ssl.nix;
    }
    |> builtins.mapAttrs (_: v: import v { inherit serviceName servicePort; });

  observability = {
    logging = {
      enable = true;
      systemdUnit = "alertmanager.service";
    };
    monitoring.enable = false;
    alerting.enable = false;
  };

  backups.enable = false;
  storage.enable = false;

  dashboard = {
    category = "Admin";
    links = [
      {
        icon = "alertmanager";
        name = "Alert manager";
      }
    ];
  };
}
