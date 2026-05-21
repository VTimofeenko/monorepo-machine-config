/**
  Simple module for `prusa_exporter`. Supports PrusaLink (HTTP) and UDP `syslog` metrics.

  Passwords can be kept out of the Nix store by mapping each printer name to a
  Systemd credential ID via `printerPasswords`. The credential source path is
  supplied separately through `systemd.services.prometheus-prusa-exporter.serviceConfig.LoadCredential`.
*/
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.prometheus.exporters.prusa_exporter;
  inherit (lib) types mkOption;

  # Go's `yaml.v3` parses JSON natively; `jq` works without extra tooling.
  format = pkgs.formats.json { };

  hasCredentials = cfg.printerPasswords != { };

  # Strip password fields only for printers that have a credential defined,
  # so plaintext passwords for non-credentialed printers are still honored.
  templateSettings = cfg.settings // {
    printers = map (
      p:
      if lib.hasAttr (p.name or "") cfg.printerPasswords then builtins.removeAttrs p [ "password" ] else p
    ) (cfg.settings.printers or [ ]);
  };

  templateFile = format.generate "prusa-template.json" templateSettings;

  # Pre-start script: copy the store template into `$RUNTIME_DIRECTORY`, then
  # inject each credential-backed password with `jq` (one pass per printer).
  configGenScript = pkgs.writeShellScript "prusa-gen-config" ''
    set -euo pipefail
    install -m 600 ${templateFile} "$RUNTIME_DIRECTORY/prusa.json"
    ${lib.concatMapStrings (
      { name, value }:
      ''
        ${lib.getExe pkgs.jq} \
          --arg printer ${lib.escapeShellArg name} \
          --rawfile pw "$CREDENTIALS_DIRECTORY/${value}" \
          '.printers = [.printers[] | if .name == $printer then . + {password: ($pw | rtrimstr("\n"))} else . end]' \
          "$RUNTIME_DIRECTORY/prusa.json" \
          > "$RUNTIME_DIRECTORY/prusa.json.tmp"
        mv "$RUNTIME_DIRECTORY/prusa.json.tmp" "$RUNTIME_DIRECTORY/prusa.json"
      ''
    ) (lib.attrsToList cfg.printerPasswords)}
  '';

  # When credentials are in use the config lives in the runtime directory;
  # otherwise point directly at the store-generated file.
  configFilePath =
    if hasCredentials then
      "/run/prometheus-prusa-exporter/prusa.json"
    else
      "${format.generate "prusa.json" cfg.settings}";
in
{
  options.services.prometheus.exporters.prusa_exporter = {
    enable = lib.mkEnableOption "Prusa prometheus exporter";

    package = lib.mkPackageOption pkgs "prusa-exporter" { };

    port = mkOption {
      type = types.port;
      default = 10009;
      description = "Port to listen on for HTTP metrics.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to listen on.";
    };

    settings = mkOption {
      type = format.type;
      default = { };
      description = ''
        Configuration for prusa_exporter (serialised to JSON, which Go's yaml.v3 reads natively).
        See <https://github.com/pubeldev/prusa_exporter> for details.

        Passwords supplied here are stored in the Nix store. Use `printerPasswords`
        to keep secrets out of the store via systemd credentials instead.

        Example:
        ```nix
        {
          printers = [
            {
              address = "192.168.1.10";
              username = "maker";
              name = "my-printer";
              type = "MK4";
              # omit password here; supply it via printerPasswords
            }
          ];
        }
        ```
      '';
    };

    printerPasswords = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        my-printer = "prusa-my-printer-password";
      };
      description = ''
        Map from printer `name` (as defined in `settings.printers`) to a
        systemd credential ID.  At start-up the credential's content is
        injected as the `password` field for that printer.

        The credential source must be registered separately:
        ```nix
        systemd.services.prometheus-prusa-exporter.serviceConfig.LoadCredential = [
          "prusa-my-printer-password:/run/secrets/prusa-my-printer"
        ];
        ```
      '';
    };

    metricsPath = mkOption {
      type = types.str;
      default = "/metrics/prusalink";
      description = "HTTP path for PrusaLink metrics.";
    };

    udpMetricsPath = mkOption {
      type = types.str;
      default = "/metrics/udp";
      description = "HTTP path for UDP syslog metrics.";
    };

    udpListenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0:8514";
      description = "Address:port to listen on for UDP syslog metrics.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open HTTP metrics port in firewall.";
    };

    openUdpFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open UDP syslog port in firewall.";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional flags to pass to prusa_exporter.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
      allowedUDPPorts = lib.mkIf cfg.openUdpFirewall [
        (lib.toInt (lib.last (lib.splitString ":" cfg.udpListenAddress)))
      ];
    };

    systemd.services.prometheus-prusa-exporter = {
      description = "Prometheus Prusa exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe cfg.package)
            "--config.file=${configFilePath}"
            "--exporter.metrics-port=${toString cfg.port}"
            "--exporter.metrics-path=${cfg.metricsPath}"
            "--exporter.udp-metrics-path=${cfg.udpMetricsPath}"
            "--udp.listen-address=${cfg.udpListenAddress}"
          ]
          ++ cfg.extraFlags
        );
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
          "AF_NETLINK" # Go uses netlink to resolve the local outbound IP address
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "~@clock @cpu-emulation @debug @module @mount @obsolete @privileged @raw-io @reboot @resources @swap";
        UMask = "0077";
      }
      // lib.optionalAttrs hasCredentials {
        ExecStartPre = configGenScript;
        RuntimeDirectory = "prometheus-prusa-exporter";
        RuntimeDirectoryMode = "0700";
      };
    };
  };
}
