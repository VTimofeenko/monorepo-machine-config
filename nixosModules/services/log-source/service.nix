/**
  Config for log shipping, implemented using vector.dev.
*/
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config) my-data;
  inherit (lib.homelab) getServiceConfig;

  srvName = "log-sink";
  srvConfig = getServiceConfig srvName;
in
{
  services.vector = {
    enable = true;
    settings = {
      sources = {
        local-journal = {
          type = "journald";
          # exclude_matches._SYSTEMD_UNIT
        };
      };
      # This table allows looking up IPs in the dataset and matching them to hostnames.
      enrichment_tables.my-data = {
        type = "file";
        file = {
          path = pkgs.writeTextFile {
            name = "my-ip-to-hostname-data.csv";
            text =
              let
                networkToRecords =
                  netName:
                  lib.pipe my-data.networks.${netName}.hostsInNetwork [
                    (lib.mapAttrsToList (name: value: "${name},${value.ipAddress}"))
                    (builtins.concatStringsSep "\n")
                  ];
              in
              ''
                hostname,ip
              ''
              + lib.concatMapStringsSep "\n" networkToRecords [
                "lan"
                "client"
              ];
          };
          encoding.type = "csv";
          schema = {
            hostname = "string";
            ip = "string";
          };
        };
      };
      sinks = {
        log-sink = {
          type = "kafka";
          inputs = [ "local-journal" ];
          encoding.codec = "json"; # TODO: protobuf?

          # bootstrap_servers = "${service.fqdn}:9092"; # TODO: fix the network resolution in this vpn
          bootstrap_servers = "10.5.0.7:9092";
          topic = srvConfig.logTopic;
        };
      };
    };
    journaldAccess = true;
  };

  # TODO: ipAllow for vector only on logging network
}
