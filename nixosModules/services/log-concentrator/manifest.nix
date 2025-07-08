let
  serviceName = "log-concentrator";
  vectorPort = 6000;
  syslogPort = 514;
in
rec {
  default = [
    module
    ingress.impl
    # storage.impl
    # backups.impl
  ];
  module = ./. + "/${serviceName}.nix";

  ingress =
    {
      impl = ./non-functional/firewall.nix;
    }
    |> builtins.mapAttrs (
      _: v:
      import v {
        servicePort = vectorPort;
        inherit serviceName syslogPort;
      }
    );

  monitoring = {
    # TODO: implement
  };
  logging = false; # TODO: implement
  storage = {
    # TODO: implement
  };

  backups.enable = false;

}
