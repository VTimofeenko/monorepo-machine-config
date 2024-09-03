{
  config,
  lib,
  ...
}:
let
  inherit (lib.homelab) getOwnIpInNetwork;
in
{
  services.prometheus.exporters.kea = {
    enable =
      assert config.services.kea.dhcp4.enable;
      true;
    listenAddress = getOwnIpInNetwork "monitoring";
    openFirewall = lib.mkForce false;
    targets = [
      config.services.kea.dhcp4.settings.control-socket.socket-name
    ];
    # This is for future when it's a list
    # lib.catAttrs "socket-name" config.services.kea.dhcp4.settings.control-sockets;
  };

  # Explodes in 2.7 -- this will be a list
  # kea and the exporter run as the same user. Unix security is fine for now
  services.kea.dhcp4.settings.control-socket = {
    socket-type = "unix";
    socket-name = "/run/kea/control.sock";
  };
}
