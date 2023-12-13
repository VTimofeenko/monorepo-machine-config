let
  inherit (import ../dns/lib.nix) mkARecord mkCNAMERecord;
in
{
  /* Produces the header for the zone file. All whitespace seems to be significant */
  mkZoneData =
    { my-data
    , domain
    , lib
    , networkName
    , services ? false
    }:
    let
      network = my-data.lib.getNetwork networkName;
    in
    ''
      $ORIGIN ${domain}.
      $TTL 1800

      @ IN SOA ns1.${domain}. admin.${domain}. (
          ${builtins.readFile ./serial} ; serial number
          28800 ; Refresh
          7200 ; Retry
          864000 ; Expire
          86400 ; Min TTL
          )

      IN NS ns1.${domain}.
      IN NS ns2.${domain}.

    ''
    +
    # DNS records for ns1 & ns 2
    lib.concatStringsSep
      "\n"
      (lib.lists.imap1 (index: value: (mkARecord "ns${toString index}" value)) network.dnsServers) # -> "ns1 IN A 192.168.1.1"
    + "\n" + # WARN: LEAVE IN PLACE

    (if services then
    # DNS records for services in network
      lib.concatMapStringsSep
        "\n"
        (service: mkCNAMERecord service.domain service.CNAME) # { .. } -> "CNAME record"
        (builtins.attrValues my-data.services.DNSRecords.${networkName}) # ->[ {..} {..} ]
    else
    # DNS records for hosts in network, if this is not a services zone
      lib.concatMapStringsSep
        "\n"
        (host: mkARecord host.hostName host.ipAddress) # {..} -> "A record"
        (builtins.attrValues network.hostsInNetwork) # -> [ {..} {..}]
    )
    +
    "\n\n"; # WARN: LEAVE IN PLACE
}
