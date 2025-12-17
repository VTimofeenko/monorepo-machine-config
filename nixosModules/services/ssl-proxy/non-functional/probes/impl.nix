/**
  Simple module for `ssl_exporter`. Only configures the basic things.
*/
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.prometheus.exporters.ssl_exporter;
  inherit (lib) types mkOption;
in
{
  options.services.prometheus.exporters.ssl_exporter = {
    enable = lib.mkEnableOption "ssl prometheus exporter";

    package = mkOption {
      type = types.package;
      description = "The ssl-exporter package to use.";
      default = pkgs.callPackage ./pkg.nix { };
    };
    port = mkOption {
      type = types.port;
      default = 9219;
      description = "Port to listen on.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to listen on.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open port in firewall.";
    };

  };

  config = lib.mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.prometheus-ssl-exporter = {
      description = "Prometheus ssl exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = ''${lib.getExe cfg.package} --web.listen-address="${cfg.listenAddress}:${toString cfg.port}"'';
        DynamicUser = true;
        Restart = "always";

        # Hardening
        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = "yes";
        ProtectSystem = "strict";
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectClock = true;
        ProtectKernelLogs = true;
        ProtectHostname = true;
        PrivateUsers = true;
        ProtectProc = "noaccess";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "~@clock @cpu-emulation @debug @module @mount @obsolete @privileged @raw-io @reboot @resources @swap";
        UMask = "0077";
      };
    };
  };
}
