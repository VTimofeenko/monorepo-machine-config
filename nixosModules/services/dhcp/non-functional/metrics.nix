{
  config,
  lib,
  self,
  ...
}:
{
  services.prometheus.exporters.kea = {
    enable =
      assert config.services.kea.dhcp4.enable;
      true;
    listenAddress = lib.homelab.getOwnIpInNetwork "backbone-inner";
    openFirewall = lib.mkForce false;
    targets = lib.catAttrs "socket-name" config.services.kea.dhcp4.settings.control-sockets;
  };

  services.kea.dhcp4.settings.control-sockets = [
    {
      socket-type = "unix";
      socket-name = "/run/kea/control.sock";
    }
  ];

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = config.services.prometheus.exporters.kea.port;
    })
  ];
}
