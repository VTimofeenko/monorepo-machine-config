/**
  Module for FilaBridge: syncs Spoolman filament usage from PrusaLink printers.

  Configuration lives in FilaBridge's SQLite database under the state
  directory. `settings` and `printers` are written into it on every start
  (local `declarative-provisioning.patch`), overwriting UI edits to those
  entries; anything not declared stays UI-managed. Toolhead → spool mappings
  are always set in the UI.

  The binary always binds `0.0.0.0:<port>` (its `-host` flag is only printed),
  so restricting access is left to the firewall.
*/
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.filabridge;
  inherit (lib) types mkOption;

  credentialsDir = "/run/credentials/filabridge.service";

  provisionFile = (pkgs.formats.json { }).generate "filabridge-provision.json" {
    config = cfg.settings;
    printers = lib.mapAttrs (
      id: p:
      {
        inherit (p) name toolheads;
        ip_address = p.address;
      }
      // lib.optionalAttrs (p.apiKeyFile != null) { api_key_file = "${credentialsDir}/printer-${id}"; }
    ) cfg.printers;
  };

  provision = cfg.settings != { } || cfg.printers != { };
in
{
  options.services.filabridge = {
    enable = lib.mkEnableOption "FilaBridge";

    package = lib.mkPackageOption pkgs "filabridge" { };

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port for the web interface and API.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        FILABRIDGE_BASE_PATH = "/filabridge";
      };
      description = "Extra environment variables passed to FilaBridge.";
    };

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        spoolman_url = "http://127.0.0.1:7912";
      };
      description = ''
        Entries of FilaBridge's `configuration` table, applied on every start.
        Keys are the `ConfigKey*` constants in upstream's `constants.go`.
      '';
    };

    printers = mkOption {
      default = { };
      description = "PrusaLink printers, keyed by FilaBridge printer ID, applied on every start.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                description = "Display name.";
              };
              address = mkOption {
                type = types.str;
                description = "PrusaLink host name or IP.";
              };
              toolheads = mkOption {
                type = types.ints.positive;
                default = 1;
                description = "Number of toolheads.";
              };
              apiKeyFile = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "File with the PrusaLink API key (the PrusaLink password). Passed as a systemd credential.";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.filabridge = {
      description = "FilaBridge";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      environment = {
        GIN_MODE = "release";
        FILABRIDGE_DB_PATH = "/var/lib/filabridge";
      }
      // lib.optionalAttrs provision { FILABRIDGE_PROVISION_FILE = provisionFile; }
      // cfg.environment;

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} -port ${toString cfg.port}";
        DynamicUser = true;
        StateDirectory = "filabridge";
        Restart = "always";
        LoadCredential = lib.mapAttrsToList (id: p: "printer-${id}:${p.apiKeyFile}") (
          lib.filterAttrs (_: p: p.apiKeyFile != null) cfg.printers
        );

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
        SystemCallFilter = [
          "@system-service"
          "~@privileged @resources"
        ];
        UMask = "0077";
      };
    };
  };
}
