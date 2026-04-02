endpoints: { lib, ... }:
{
  services.prometheus.alertmanager = {
    port = endpoints.web.port;
    listenAddress = lib.homelab.getServiceInnerIP "alert-manager";
  };
}
