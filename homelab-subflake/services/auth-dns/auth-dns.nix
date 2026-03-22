/**
  Base NSD configuration for authoritative DNS.

  Sets up:
  - NSD daemon configuration
  - Base zone structures (SOA and NS records)
  - Imports functional modules that populate zone records
*/
{ lib, ... }:
{
  imports = lib.localLib.mkImportsFromDir ./functional;

  services.nsd = {
    enable = true;
    # Port and interface configuration in non-functional/endpoints-config.nix
  };
}
