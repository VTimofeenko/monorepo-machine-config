/**
  Oxygen-specific network config.

  Oxygen is currently using an old broadcom adapter:

  # ethtool output:
  driver: wl0
  version: 6.30.223.271 (r587334)
  firmware-version:
  expansion-rom-version:
  bus-info: 0000:03:00.0
  supports-statistics: no
  supports-test: no
  supports-eeprom-access: no
  supports-register-dump: no
  supports-priv-flags: no

  # networkctl output:
  Model: BCM4352 802.11ac Dual Band Wireless Network Adapter
*/
{ lib, ... }:
{
  imports = [ ];

  networking = {
    wireless = {
      iwd.enable = true;
      enable = lib.mkForce false; # Disable wpa_supplicant in favor of iwd
    };
    defaultGateway.interface = "phy-lan"; # This may be needed by default...
  };

  # If I need to debug network:
  # environment.systemPackages = [ pkgs.ethtool pkgs.toybox ]; # debug network

  # Original network manager config:
  # # Networking, specific to this host
  # networking = {
  #   wireless.enable = false;
  #   networkmanager.enable = true; # For whatever reason this host needed networkmanager to get to wifi.
  # };
  # # W/a for network manager wait online failing
  # # Source: https://github.com/NixOS/nixpkgs/issues/180175
  # systemd.services.NetworkManager-wait-online = {
  #   serviceConfig = {
  #     ExecStart = [
  #       ""
  #       "${pkgs.networkmanager}/bin/nm-online -q"
  #     ];
  #   };
  # };

}
