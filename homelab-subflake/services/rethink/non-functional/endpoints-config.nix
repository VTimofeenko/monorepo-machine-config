endpoints:
{ lib, ... }:
{
  services.rethink.settings.management_port = {
    bind = endpoints.web.port;
    address = lib.homelab.getServiceInnerIP "rethink";
  };
}
