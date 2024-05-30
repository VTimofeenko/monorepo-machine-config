{ lib, ... }:
let
  inherit (lib.homelab) getServiceConfig getOwnIpInNetwork;
in
{
  services.openntpd = {
    enable = true;
    servers = (getServiceConfig "ntp").upstream;
    extraConfig = ''
      listen on ${(getOwnIpInNetwork "lan")}
    '';
  };
}
