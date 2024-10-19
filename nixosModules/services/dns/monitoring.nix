{ config, lib, ... }:
let
  inherit (lib.homelab) getOwnIpInNetwork;
in
{
  services = {
    unbound.settings.server.extended-statistics = "yes";

    prometheus.exporters.unbound = {
      enable =
        assert config.services.unbound.enable;
        true;
      unbound.host = "unix:///run/unbound/unbound.socket";
      listenAddress = getOwnIpInNetwork "monitoring";
      openFirewall = lib.mkForce false;
    };
  };

  networking.firewall.interfaces.monitoring.allowedTCPPorts = lib.singleton config.services.prometheus.exporters.unbound.port;
}
