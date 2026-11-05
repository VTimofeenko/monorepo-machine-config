{ ... }:
{
  module = ./bentopdf.nix;

  endpoints.web = {
    port = 80; # No port conflict, this should merge with existing nginx
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  dashboard = {
    category = "Home";
    links = [
      {
        name = "BentoPDF";
        icon = "bentopdf";
        description = "PDF toolkit";
      }
    ];
  };
}
