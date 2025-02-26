{ lib, config, ... }:
let
  settings.listenInterface = "backbone-inner";
in
{
  services.gitea.settings.server = {
    SSH_LISTEN_HOST = lib.homelab.getOwnIpInNetwork settings.listenInterface;
  };

  # Allow binding on port 22
  systemd.services.gitea = {
    serviceConfig = {
      # These settings enable gitea built-in server to bind to port 22
      # Source: archwiki
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE";
      PrivateUsers = lib.mkForce false;
    };
  };

  networking.firewall.extraInputRules =
    [
      config.services.gitea.settings.server.HTTP_PORT
      config.services.gitea.settings.server.SSH_PORT
    ]
    |> map (
      it:
      [
        ''ip saddr ${lib.homelab.getHostIpInNetwork "fluorine" "backbone-inner"}'' # TODO: parameterize this as the global SSL proxy
        ''tcp dport ${it |> toString} accept;''
      ]
      |> builtins.concatStringsSep " "
    )
    |> lib.concatLines;
}
