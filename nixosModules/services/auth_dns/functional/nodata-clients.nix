/**
  Apple devices ask for a set of records to do discovery. I am not interested
  in providing a response.

  Default is NXDomain, but I don't want to pollute my logs.

  Solution: add 'IN A' replies. Questions should come for `PTR` records, so the
  answer will be `NODATA`.
*/
{ lib, ... }:
let
  nodataRecords = [
    "lb._dns-sd._udp"
    "db._dns-sd._udp"
    "b._dns-sd._udp"
    "_aaplcache2._tcp" # If I ever get to running the Apple update cache – this will need to be updated
  ];
  lan = lib.homelab.getNetwork "lan";
  mainDNS = lan |> builtins.getAttr "dnsServers" |> builtins.head;
  data =
    nodataRecords
    # Add A record. No `PTR` record => `NODATA` reply
    |> map (it: "${it} IN A ${mainDNS}")
    # Turn into a single string
    |> lib.concatLines
    # Add header and footer
    |> (it: "; NODATA for Apple queries\n${it}\n");
in
{
  services.nsd.zones = lib.mkBefore {
    # Main zone
    ${lan |> lib.getAttr "domain"}.data = data;
    # Reverse zone (`in-addr.arpa.`)
    ${
      lan
      |> lib.getAttr "subnet"
      |> lib.localLib.splitReverseJoin
      |> (it: "${it}.in-addr.arpa")
    }.data =
      ''
        ; Dummy record to fix weird queries from Apple devices
        0 IN PTR network.home.arpa.
        0 IN NS ns1.home.arpa.

      '';
  };
}
