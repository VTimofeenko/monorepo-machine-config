{ config, lib, hosts, private-config, ... }:
let
  infra = lib.importTOML <hosts> /infra.toml;
  inherit (infra.network) lan;
  local_address = lan.first_octets + "." + lan."${config.networking.hostName}".ip;
in
{
  imports = [
    private-config.nixosModules.home-wireless-fast-client
    # NOTE: should be kept commented until I need it
    # private-config.nixosModules.phone-shared-network
  ];
  networking.interfaces.wlp170s0 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = local_address;
        prefixLength = lan.prefix;
      }
    ];
  };
}
