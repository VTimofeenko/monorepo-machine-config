{ config, lib, ... }:
let
  inherit (lib.homelab) getOwnIpInNetwork;
in
{
  services = {
    # Needed settings for stats
    unbound.settings = {
      server.extended-statistics = "yes";
      remote-control.control-enable = true;
    };
    prometheus.exporters.unbound = {
      enable =
        assert config.services.unbound.enable;
        true;
      unbound.host = "unix:///run/unbound/unbound.socket";
      listenAddress = getOwnIpInNetwork "backbone-inner";
      openFirewall = lib.mkForce false;
    };
  };
}
