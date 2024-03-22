/**
  Implementation for local Firefox sync server.

  Since syncserver in nixpkgs uses mysql as the only supported database and my main db is on postgres -- this service will live in its own container.
*/
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config) my-data;
  srvName = "firefox-syncserver";
  service = my-data.lib.getService srvName;
in
{
  age.secrets.firefox-syncserver = {
    file = my-data.lib.getSrvSecret srvName "syncserver-secrets";
  };

  containers.firefox-syncserver = {
    bindMounts = {
      "syncserver-secrets" = {
        isReadOnly = true;
        mountPoint = "/super-secret";
        hostPath = config.age.secrets.firefox-syncserver.path;
      };
    };
    autoStart = true;

    # Container network config
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";

    # bindMounts = {
    #   /* This should cover all container's persistence needs */
    #   "/var/lib" = {
    #     # hostPath = "/srv/luks_data/${db_ct_name}";
    #     isReadOnly = false;
    #   };
    config =
      { config, ... }:
      {
        networking.firewall.allowedTCPPorts = [ config.services.firefox-syncserver.settings.port ];
        services = {
          firefox-syncserver = {
            enable = true;
            secrets = "/super-secret"; # TODO: let binding
            singleNode = {
              enable = true; # Setup is simple
              hostname = service.domain;
              enableNginx = false; # SSL termination done on host
            };
          };
          mysql.package = pkgs.mariadb;
        };

        system.stateVersion = "23.11";
        # Socat to proxy traffic from 5000 on ${localAddress} to 127.0.0.1
        systemd.services.port-punch = {
          wantedBy = [ "firefox-syncserver.service" ];
          startLimitIntervalSec = 11;
          startLimitBurst = 5;
          serviceConfig = {
            Environment = [ "SOCAT_SOCKADDR=192.168.100.11" ];
            Type = "simple";
            # Before start - make sure the loopback adapter is brought up
            ExecStart =
              let
                inherit (config.services.firefox-syncserver.settings) port;
              in
              ''
                ${lib.getExe pkgs.socat} tcp-listen:${toString (port + 1)},fork,reuseaddr TCP:127.0.0.1:${toString port}
              '';
            Restart = "always";
            RestartSec = 2;
          };
          unitConfig = {
            Description = "Exposes the firefox-syncserver port on the container's IP";
          };
        };
      };
  };
}
