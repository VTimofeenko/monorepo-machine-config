{ config
, ...
}:
let
  inherit (config) my-data;

  srvName = "ntp";
  fwSrvName = "wan_firewall";

  fwConfig = my-data.lib.getServiceConfig fwSrvName;
in
{
  networking.nftables.ruleset =
    assert (my-data.services.all.${srvName}.onHost == my-data.services.all.${fwSrvName}.onHost); # relies on the fact that this is running on router
    with fwConfig; ''
      table inet ${mainTable} {
        chain ${lanChain} {
          udp dport 123 accept comment "NTP traffic"
        }
      }
    '';
}
