endpoints: { lib, ... }:
{
  services.prometheus = {
    port = endpoints.web.port;
    listenAddress = lib.homelab.getServiceInnerIP "prometheus";
  };
}
