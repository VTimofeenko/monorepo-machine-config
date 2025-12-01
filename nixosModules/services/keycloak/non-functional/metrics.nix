{ port, ... }:
{ self, lib, ... }:
{
  services.keycloak.settings = {
    metrics-enabled = true;
    http-management-scheme = "http"; # Otherwise breaks current implementation of Prometheus scrape
    event-metrics-user-enabled = true;
  };

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib port;
    })
  ];
}
