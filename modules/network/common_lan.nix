{ lib, infra, ... }:
let
  infraMetadata = lib.importTOML (infra + "/infra.toml");
  inherit (infraMetadata.network) lan;
in
{
  networking.enableIPv6 = false;
  networking.nameservers = lan.dns_servers;
}
