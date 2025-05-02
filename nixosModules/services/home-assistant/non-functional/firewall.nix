{ port, ... }:
{
  lib,
  self,
  ...
}:
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ port ];
    })
  ];

  services.home-assistant.config.http = {
    server_port = port;
    server_host = lib.homelab.getOwnIpInNetwork "backbone-inner";
    trusted_proxies = [
      (lib.homelab.getHostIpInNetwork "fluorine" "backbone-inner")
    ];
    use_x_forwarded_for = true;
  };
}
