{ ... }:
{
  module = ./excalidash.nix;

  endpoints.web = {
    port = 6767;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  # sslProxyConfig omitted — auto-generated standard reverse proxy (with
  # websockets, needed for socket.io) to the `web` endpoint is sufficient;
  # the actual `/` vs `/api` vs `/socket.io` split happens locally, see
  # ./non-functional/endpoints-config.nix.

  database.create = true;

  dashboard = {
    category = "Home";
    links = [
      {
        name = "ExcaliDash";
        icon = "excalidraw";
        description = "Self-hosted Excalidraw dashboard";
      }
    ];
  };

  documentation = ./README.md;
}
