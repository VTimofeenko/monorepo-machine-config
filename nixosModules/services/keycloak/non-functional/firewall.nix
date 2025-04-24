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
        config.services.keycloak.settings.https-port
      ];
    })
  ];
}
