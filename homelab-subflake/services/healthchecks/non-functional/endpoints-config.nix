endpoints: { lib, ... }:
{
  # Establish listening port and address
  services.healthchecks = {
    port = endpoints.web.port;
    listenAddress = lib.homelab.getOwnIpInNetwork "backbone-inner";
  };
}
