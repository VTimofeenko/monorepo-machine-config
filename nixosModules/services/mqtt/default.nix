/**
  Module that configures MQTT.
*/
_: {
  imports = [
    ./service.nix
    ./firewall.nix
    ./ssl.nix
  ];
}
