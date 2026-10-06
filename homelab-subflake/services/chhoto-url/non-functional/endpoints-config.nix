endpoints: { lib, ... }:
{
  services.chhoto-url.settings = {
    inherit (endpoints.web) port;
    listen_address = lib.homelab.getServiceInnerIP "chhoto-url";
  };
}
