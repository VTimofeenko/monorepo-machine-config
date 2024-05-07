/**
  Implements the ingestion framework using Kafka.
*/
{
  config,
  lib,
  redpanda-flake,
  pkgs,
  ...
}:
let
  inherit (config) my-data;
  # srvName = "log-sink";
  # service = my-data.lib.getService srvName;

  loggingIP = (my-data.lib.getOwnHostInNetwork "logging").ipAddress;

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
    # TODO:
    # admin.username
    # admin.password
  };

  # Enforce CPU limit
  # The cooler whine on nitrogen is too much to bear and I don't need the logs _that_ fast
  systemd.services.redpanda.serviceConfig.CPUQuota = "15%";
}
