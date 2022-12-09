{ lib, hosts, ... }:
let
  infra = lib.importTOML (hosts + "./infra.toml");
  inherit (infra.network) lan;
in
{
  networking.enableIPv6 = false;
  networking.nameservers = lan.dns_servers;
}
