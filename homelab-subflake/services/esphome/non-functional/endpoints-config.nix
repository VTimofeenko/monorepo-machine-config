endpoints: { lib, ... }:
{
  services.esphome = {
    port = endpoints.web.port;
    address = lib.homelab.getOwnIpInNetwork "backbone-inner";
  };
}
