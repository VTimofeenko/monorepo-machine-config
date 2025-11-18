{ lib, ... }:
let
  inherit (lib.homelab) getServiceConfig getService getHostIpInNetwork;
  nftConcat = lib.concatStringsSep ", ";

  srvName = "nut-server";

  clientIPs = lib.pipe "nut-client" [
    getService
    (builtins.getAttr "onHosts")
    (lib.concat [ "nas" ]) # Manually add non-managed NAS in this context
    (map (lib.flip getHostIpInNetwork "lan"))
  ];
in
{
  networking.myFirewall.chains.input-lan-br.rules = ''
    tcp dport ${toString (getServiceConfig srvName).port} ip saddr { ${nftConcat clientIPs}} accept comment "NUT traffic"
  '';

  power.ups.upsd.listen = [
    {
      address = lib.homelab.getServiceIP srvName;
    }
  ];
}
