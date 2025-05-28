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

  # Default ("::") fails with
  # java.nio.channels.UnsupportedAddressTypeException
  services.keycloak.settings.http-host = "0.0.0.0";
}
