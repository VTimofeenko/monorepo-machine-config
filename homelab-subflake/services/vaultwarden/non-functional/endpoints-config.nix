endpoints:
{ lib, ... }:
{
  services.vaultwarden.config = {
    ROCKET_ADDRESS = lib.homelab.getOwnIpInNetwork "backbone-inner";
    ROCKET_PORT = endpoints.web.port;
  };
}
