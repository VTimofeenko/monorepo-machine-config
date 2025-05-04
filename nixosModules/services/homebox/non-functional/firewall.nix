{ port, ... }:
{ lib, self, ... }:
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];

  # Make sure the appropriate port is set in the service
  services.homebox.settings.HBOX_WEB_PORT = port |> toString;
}
