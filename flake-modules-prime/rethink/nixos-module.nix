{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.rethink;
  format = pkgs.formats.json { };
  stateDir = "/var/lib/rethink";
in
{
  options = {
    services.rethink = {
      enable = lib.mkEnableOption "rethink, a local LG ThinQ cloud replacement";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.rethink;
        description = "The rethink package to use.";
      };

      # TODO: MQTT password secret. rethink only reads `homeassistant.mqtt_pass`
      # from the config file, so a `mqttPasswordFile` would need to merge it
      # into a runtime config in the state dir before start.
      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = format.type;

          options = {
            hostname = lib.mkOption {
              type = lib.types.str;
              example = "rethink.lan";
              description = "Name devices use to reach rethink. Must not be an IP address.";
            };

            # Relative paths resolve against the config file's directory,
            # which is the read-only store here.
            ca_key_file = lib.mkOption {
              type = lib.types.str;
              default = "${stateDir}/ca.key";
              description = "CA private key, created on first run.";
            };

            ca_cert_file = lib.mkOption {
              type = lib.types.str;
              default = "${stateDir}/ca.cert";
              description = "CA certificate, created on first run.";
            };
          };
        };
        description = ''
          Configuration for rethink, see upstream `config.jsonc` for all keys:
          <https://github.com/anszom/rethink/blob/master/config.jsonc>.

          Ports below 1024 cannot be bound by the service; use `bind` +
          `advertise` and redirect. If `bridge` is set, point
          `bridge.storage_path` into ${stateDir}.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.rethink = {
      description = "rethink LG ThinQ cloud replacement";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} ${format.generate "rethink.json" cfg.settings}";
        Restart = "always";

        DynamicUser = true;
        StateDirectory = "rethink";
        StateDirectoryMode = "0700";
        WorkingDirectory = stateDir;

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        CapabilityBoundingSet = "";
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
      };
    };
  };
}
