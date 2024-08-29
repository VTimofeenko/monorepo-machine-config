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
        local-journal-nixos = {
          type = "journald";
          include_matches = {
            SYSLOG_IDENTIFIER = [ "nixos" ];
          };
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

      # This transformation parses nixos switch events in journald
      # and emits filtered data with the target version and status
      transforms.parse-nixos-events = {
        type = "remap";
        inputs = [ "local-journal-nixos" ];
        source = # vrl
          ''
            # Skip the "starting" message
            .message = string!(.message)
            if contains(.message, "switching to") && !contains(.message, "(status") && !contains(.message, "finished") {
                abort
            }

            # Extract target version and status of switch
            # .*? is non-greedy match for hostname
            target_version = parse_regex!(.message, r'.*nixos-system-.*?-(?P<version>.*)').version
            status = parse_regex(.message, r'status (?P<status>\d)').status ?? 0

            # Store needed values
            host = .host
            ts = .timestamp  # "timestamp" is reserved

            # clear the object
            del(.)

            # Reconstruct the values
            .target_version = target_version
            .host = host
            .timestamp = ts
            .status = status
          '';
      };

      sinks = rec {
        log-sink = {
          type = "kafka";
          inputs = [ "local-journal" ];
          encoding.codec = "json"; # TODO: protobuf?

          # bootstrap_servers = "${service.fqdn}:9092"; # TODO: fix the network resolution in this vpn
          bootstrap_servers = "10.5.0.7:9092";
          topic = srvConfig.logTopic;
        };
        log-nixos-version-history = log-sink // {
          inputs = [ "parse-nixos-events" ];
          topic = srvConfig.deploymentsTopic;
        };
      };
    };
    journaldAccess = true;
  };

  # TODO: ipAllow for vector only on logging network
}
