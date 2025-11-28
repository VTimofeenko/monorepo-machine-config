let
  serviceName = "pgadmin";
in
rec {
  default = [
    module
    ingress.impl
    # SSO.impl # TODO: implement
  ];
  module = ./pgadmin.nix;

  ingress =
    let
      port = 5050;
    in
    {
      impl = ./non-functional/firewall.nix;
      sslProxyConfig = ./non-functional/ssl.nix;
    }
    |> builtins.mapAttrs (_: v: import v { inherit port serviceName; });

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "Database admin panel";
        icon = "pgadmin";
        name = "pgAdmin";
      }
    ];
  };
}
