{ config
, ...
}:
let
  inherit (config) my-data;

  srvName = "ntp";
  fwSrvName = "wan_firewall";

  # thisSrvConfig = localLib.getSrvConfig srvName;
  fwConfig = my-data.lib.getSrvConfig fwSrvName;
in
{
  networking.nftables.ruleset =
    assert (my-data.services.all.${srvName}.hostedAt == my-data.services.all.${fwSrvName}.hostedAt); # relies on the fact that this is running on router
    with fwConfig; ''
      table inet ${mainTable} {
        chain ${lanChain} {
          udp dport 123 accept comment "NTP traffic"
        }
      }
    '';
}
