let
  serviceName = "tt-rss";
in
rec {
  default = [
    module
    ingress.impl
  ];
  module = ./. + "${serviceName}.nix";

  ingress =
    let
      port = 80;
    in
    {
      impl = ./non-functional/firewall.nix;
      sslProxyConfig = ./non-functional/ssl.nix;
    }
    |> builtins.mapAttrs (_: v: import v { inherit port serviceName; });

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
