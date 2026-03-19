{ lib, ... }:
let
  # Metrics port from endpoints (9167)
  metricsPort = 9167;
in
{
  services = {
    # Needed settings for stats
    unbound.settings = {
      server.extended-statistics = "yes";
      remote-control.control-enable = true;
    };
    prometheus.exporters.unbound = {
      enable = true;
      unbound.host = "unix:///run/unbound/unbound.socket";
      # Listen on backbone-inner interface
      listenAddress = lib.homelab.getOwnIpInNetwork "backbone-inner";
      port = metricsPort;
      openFirewall = false;
    };
  };

  # Firewall rule auto-generated from endpoints.metrics by manifest merge system
}
