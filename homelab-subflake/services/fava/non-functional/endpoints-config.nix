endpoints: { lib, ... }:
{
  services.fava = {
    host = lib.homelab.getOwnIpInNetwork "backbone-inner";
    port = endpoints.web.port;
  };

  services.fava-helper.settings = {
    webhook.listen = "${lib.homelab.getOwnIpInNetwork "backbone-inner"}:${endpoints.webhook.port |> toString}";
    metrics.listen = "${lib.homelab.getOwnIpInNetwork "backbone-inner"}:${endpoints.metrics.port |> toString}";
  };
}
