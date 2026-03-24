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
    |> (lib.mapAttrs' (
      _: v:
      lib.nameValuePair (v.subnet |> splitReverseJoin |> (it: "${it}.in-addr.arpa")) (
        v.hostsInNetwork
        |> builtins.attrValues
        |> (map (it: {
          inherit (it) fqdn;
          domainName = it.ipAddress |> lib.removePrefix "${v.subnet}" |> splitReverseJoin;
        }))
        |> map (it: srvLib.mkRecord "PTR" it.domainName it.fqdn)
      )
    )) # -> `{ reverseZoneName = [ record ... ]  } `
    |> lib.mapAttrs (
      n: v: {
        data = ''
          $ORIGIN ${n}.
          $TTL 86400
          @ IN SOA ns1.home.arpa. admin.home.arpa. (
              ${builtins.readFile ../../serial} ; Serial
              3600       ; Refresh
              900        ; Retry
              1209600    ; Expire
              86400 )    ; Minimum TTL

          @ IN NS ns1.home.arpa.
          @ IN NS ns2.home.arpa.

          ${lib.concatStringsSep "\n" v}
        '';
      }
    );
}
