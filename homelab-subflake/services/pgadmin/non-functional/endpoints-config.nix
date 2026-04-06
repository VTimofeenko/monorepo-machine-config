endpoints: { lib, ... }:
{
  # Listen only on backbone-inner
  services.pgadmin = {
    port = endpoints.web.port;
    settings.DEFAULT_SERVER = "pgadmin" |> lib.homelab.getServiceInnerIP;
  };
}
