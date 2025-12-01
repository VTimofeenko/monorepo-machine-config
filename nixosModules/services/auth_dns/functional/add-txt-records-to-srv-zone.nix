/**
  Adds `TXT` records for domains in the `srv.` zone.
*/
{ lib, ... }:
let
  inherit (lib.homelab.getSettings) publicDomainName;
in
{
  services.nsd.zones = lib.mkBefore {
    "${publicDomainName}".data =
      (lib.homelab.getServiceConfig "auth_dns").zoneRecords."${publicDomainName}".data
      |> lib.attrNames
      # I am using CNAME records to send clients to appropriate SSL proxy
      # RFC 1034 sez "thou shalt not have CNAME and other record for thy node"
      # So I create `_i.<domainName> TXT` records
      |> map (
        it: "_i.${it} IN TXT @ ${it |> lib.homelab.services.fromDomain |> lib.homelab.getServiceHost}"
      )
      |> lib.concatLines
      |> (it: "${it}\n");
  };
}
