let
  serviceName = "log-concentrator";
  vectorPort = 6000;
  syslogPort = 514;
  accessLogConcentratorPort = 9514;
in
rec {
  default = [
    module
    ingress.impl
  ]
  ++ observability.impl;

  module = ./. + "/${serviceName}.nix";

  ingress =
    {
      impl = ./non-functional/firewall.nix;
    }
    |> builtins.mapAttrs (
      _: v:
      import v {
        servicePort = vectorPort;
        inherit serviceName syslogPort accessLogConcentratorPort;
      }
    );

  observability = rec {
    enable = true;
    impl = [ metrics.impl ];
    metrics = rec {
      enable = true;
      impl = if enable then import ./non-functional/metrics.nix { inherit port; } else { };
      port = 8087;
    };
  };
  logging = false; # TODO: implement
  storage = {
    # TODO: implement
  };

  backups.enable = false;

}
