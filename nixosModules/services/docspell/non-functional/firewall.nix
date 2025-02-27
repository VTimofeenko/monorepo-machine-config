{
  config,
  lib,
  self,
  ...
}:
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [
        config.services.docspell-restserver.bind.port
        8002 # file manager port
      ];
    })
  ];

  config.services.docspell-restserver.bind = {
    address = lib.homelab.getOwnIpInNetwork "backbone-inner";
    port = 7880;
  };
}
