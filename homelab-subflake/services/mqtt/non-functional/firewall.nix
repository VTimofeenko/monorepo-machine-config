{ lib, ... }:
# TODO: this basically lets it listen on LAN, change when finalizing S2S network
{
  networking.firewall.allowedTCPPorts = [ (lib.homelab.getManifest "mqtt").endpoints.mqtt.port ];
}
