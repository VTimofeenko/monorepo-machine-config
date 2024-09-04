{ lib, ... }:
let
  inherit (lib.homelab) getOwnIpInNetwork;
in
{
  services.ntpd-rs = {
    enable = true;
    useNetworkingTimeServers = true;
    settings = {
      server = [
        {
          listen = "${getOwnIpInNetwork "lan"}:123";
        }
      ];
    };
    metrics.enable = true;
  };
}
