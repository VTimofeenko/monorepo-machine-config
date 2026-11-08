{ lib, self, ... }:
let
  inherit (lib.homelab.getManifest "rethink") endpoints srvLib;
  applianceIPs = srvLib.appliances |> map (name: lib.homelab.getHostIpInNetwork name "lan");
in
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
      inherit lib;
      ports = [ endpoints.web.port ];
    })
  ];

  # Appliance-facing HTTPS + MQTTS
  networking.firewall.extraInputRules = ''
    ip saddr { ${lib.concatStringsSep ", " applianceIPs} } tcp dport { 443, 8883 } accept
  '';
}
