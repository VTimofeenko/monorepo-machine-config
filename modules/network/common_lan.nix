{ lib, infra, ... }:
let
  infraMetadata = lib.importTOML (infra + "/infra.toml");
  inherit (infraMetadata.network) lan;
in
{
  networking.enableIPv6 = false;
}
