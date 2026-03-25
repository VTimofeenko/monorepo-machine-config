/**
  Create reverse zones for all IPs
*/
{ lib, ... }:
let
  inherit (lib.localLib) splitReverseJoin;
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
in
{

  services.nsd.zones =
    lib.homelab.networks.getAll
    |> lib.mapAttrs' (
      netName: net:
      let
        reverseZone = net.subnet |> splitReverseJoin |> (it: "${it}.in-addr.arpa");
        ptrRecords =
          net.hostsInNetwork
          |> builtins.attrValues
          |> map (it: {
            inherit (it) fqdn;
            domainName = it.ipAddress |> lib.removePrefix "${net.subnet}." |> splitReverseJoin;
          })
          |> map (it: srvLib.mkRecord "PTR" it.domainName it.fqdn);
      in
      lib.nameValuePair reverseZone {
        data =
          [
            # Zone header with network-specific nameservers
            (srvLib.mkReverseZoneBase {
              inherit reverseZone;
              forwardDomain = net.domain;
              nameserverIPs = net.dnsServers;
            })

            # PTR records
            ptrRecords
          ]
          |> lib.flatten
          |> lib.concatStringsSep "\n";
      }
    );
}
