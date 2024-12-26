/**
  Implements the ingestion framework using Kafka.
*/
{
  lib,
  redpanda-flake,
  pkgs,
  ...
}:
let
  inherit (lib.homelab) getOwnIpInNetwork;
  # srvName = "log-sink";
  # service = my-data.lib.getService srvName;

  loggingIP = getOwnIpInNetwork "logging";

  redpanda-flake-packages' = redpanda-flake.packages.${pkgs.system};
in
{
  imports = [ redpanda-flake.nixosModules.redpanda ];

  # Source: https://github.com/fornybar/redpanda.nix/blob/main/modules/redpanda.nix
  services.redpanda = {
    enable = true;
    openPorts = lib.mkForce false; # I need specific FW config, not the default one
    packages = {
      client = redpanda-flake-packages'.redpanda-client-bin;
      server = redpanda-flake-packages'.redpanda-server-bin;
    };
    broker.settings = {
      pandaproxy.pandaproxy_api = lib.mkForce [
        {
          address = "0.0.0.0";
          port = 8083; # This conflicts with another service on 8082
        }
      ];
      redpanda.advertised_kafka_api = [
        # Listeners that the broker advertises
        {
          address = loggingIP;
          port = 9092;
        }
      ];
    };
  };

  # Drop the 'local-fs' require, it leads to unnecessary restarts when nixos switch is done
  systemd.services.redpanda-setup.requires = lib.mkForce [ "network-online.target" ];
  systemd.services.redpanda.requires = lib.mkForce [ "network-online.target" ];

  # Redpanda needs this to be higher
  boot.kernel.sysctl."fs.aio-max-nr" = 1048576;

  # Enforce CPU limit
  # The cooler whine on nitrogen is too much to bear and I don't need the logs _that_ fast
  systemd.services.redpanda.serviceConfig.CPUQuota = "15%";
}
