{ lib, ... }:
let
  inherit (lib.homelab) getHostIpInNetwork getServiceIP;
  nftConcat = lib.concatStringsSep ", "; # TODO: migrate into gateway `srvLib`?

  srvName = "nut-server";

  # TODO: restore this, nut-client should probably be a trait

  # ```
  # clientIPs = lib.pipe "nut-client" [
  #   getService
  #   (builtins.getAttr "onHosts")
  #   (lib.concat [ "nas" ]) # Manually add non-managed NAS in this context
  #   (map (lib.flip getHostIpInNetwork "lan"))
  # ];
  # ```

  clientIPs = [ "nas" ] |> (map (lib.flip getHostIpInNetwork "lan"));

in
{
  # TODO: pass `dport` from endpoints in the manifest
  networking.myFirewall.chains.input-lan-br.rules = ''
    tcp dport 3493 ip saddr { ${nftConcat clientIPs}} accept comment "NUT traffic"
  '';

  # Should be LAN only
  # TODO: migrate to `endpointsConfig`
  power.ups.upsd.listen = [
    {
      address = getServiceIP srvName;
    }
  ];
}
