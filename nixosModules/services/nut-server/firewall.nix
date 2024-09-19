{ config, lib, ... }:
let
  inherit (fwConfig) mainTable lanChain;
  inherit (lib.homelab) getServiceConfig getService getHostIpInNetwork;
  nftConcat = lib.concatStringsSep ", ";

  srvName = "nut-server";
  fwSrvName = "wan_firewall";

  fwConfig = getServiceConfig fwSrvName;

  clientIPs = lib.pipe "nut-client" [
    getService
    (builtins.getAttr "onHosts")
    (lib.concat [ "nas" ]) # Manually add non-managed NAS in this context
    (map (lib.flip getHostIpInNetwork "lan"))
  ];
in
{
  networking.nftables.ruleset =
    assert (config.networking.hostName == (getService fwSrvName).onHost); # relies on the fact that this is running on router
    ''
      table inet ${mainTable} {
        chain ${lanChain} {
          tcp dport ${toString (getServiceConfig srvName).port} ip saddr { ${nftConcat clientIPs}} accept comment "NUT traffic"
        }
      }
    '';
}
