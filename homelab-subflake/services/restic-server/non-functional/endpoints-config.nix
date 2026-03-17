endpoints: { lib, ... }:
{
  # Configure restic-server listen address
  services.restic.server.listenAddress = endpoints.web.port |> toString;
}
