endpoints: { lib, ... }:
{
  services.lubelogger = {
    port = endpoints.web.port;
    settings."Kestrel__Endpoints__Http__Url" =
      "http://${lib.homelab.getOwnIpInNetwork "backbone-inner"}:${endpoints.web.port |> toString}";
  };
}
