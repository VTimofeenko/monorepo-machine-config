{
  config,
  lib,
  self,
  ...
}:
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
      listenAddress = lib.homelab.getOwnIpInNetwork "backbone-inner";
      openFirewall = lib.mkForce false;
    };
  };

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = config.services.prometheus.exporters.unbound.port;
    })
  ];
}
