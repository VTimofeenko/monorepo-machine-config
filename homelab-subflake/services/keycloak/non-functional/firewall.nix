{ lib, ... }:
{
  networking.firewall.extraInputRules  = ''
    ip daddr ${lib.homelab.getOwnIpInNetwork "lan"} tcp dport 443 accept comment "keycloak main web port"
    ip daddr ${lib.homelab.getOwnIpInNetwork "backbone-inner"} tcp dport 443 accept comment "keycloak main web port"
  '' ;
}
