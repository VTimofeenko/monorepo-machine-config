/**
  Implements `ssl_exporter` probe
  Ref:
  - https://github.com/ribbybibby/ssl_exporter
*/
{ port, ... }:
{ self, lib, ... }:
{
  services.prometheus.exporters.ssl_exporter = {
    enable = true;
    inherit port;
  };

  imports = [
    ./impl.nix
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib port;
    })
  ];
}
