let
  inherit (import ../dns/lib.nix) mkARecord mkCNAMERecord;
in
{
  # Produces the header for the zone file. All whitespace seems to be significant
  mkZoneData =
    {
      domain,
      recordsData,
      lib,
    }:
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
      lib.concatStringsSep "\n" (
        lib.lists.imap1 (index: value: (mkARecord "ns${toString index}" value)) recordsData.dns
      ) # -> "ns1 IN A 192.168.1.1"
    + "\n"
    # WARN: LEAVE IN PLACE
    +

      lib.concatStringsSep "\n" (
        lib.mapAttrsToList
          (
            domainName: recordValue:
            if recordsData.recordType == "CNAME" then
              mkCNAMERecord domainName recordValue
            else
              mkARecord domainName recordValue
          )
          recordsData.data
      )
    + "\n\n" # WARN: LEAVE IN PLACE
  ;
}
