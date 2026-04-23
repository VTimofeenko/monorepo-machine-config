{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    mkIf
    mkEnableOption
    types
    ;
  cfg = config.services.fava;
in
{
  options.services.fava = {
    enable = mkEnableOption "Fava — web interface for Beancount files";

    package = lib.mkPackageOption pkgs "fava" { };

    user = mkOption {
      type = types.str;
      default = "fava";
      description = "User account under which Fava runs.";
    };

    group = mkOption {
      type = types.str;
      default = "fava";
      description = "Group under which Fava runs.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host to listen on.";
    };

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port to listen on.";
    };

    beancountFile = mkOption {
      type = types.str;
      description = ''
        Path to the beancount file to serve. Typically points into the
        checkout managed by fava-helper.
      '';
      example = "/var/lib/fava-helper/budget/main.beancount";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--read-only" ];
      description = "Extra command-line arguments passed to fava.";
    };
  };

  config = mkIf cfg.enable {
    users.users = lib.mkIf (cfg.user == "fava") {
      fava = {
        isSystemUser = true;
        group = cfg.group;
        description = "Fava service user";
      };
    };

    users.groups = lib.mkIf (cfg.group == "fava") {
      fava = { };
    };

    systemd.services.fava = {
      description = "Fava — web interface for Beancount files";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "fava-helper.service"
      ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs (
          [
            "${lib.getExe cfg.package}"
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
          ]
          ++ cfg.extraArgs
          ++ [ cfg.beancountFile ]
        );

        User = cfg.user;
        Group = cfg.group;

        # StateDirectory makes /var/lib/fava rw for the fava user.
        # mode 0770 so fava-helper (same group) can write the beancount checkout here.
        StateDirectory = "fava";
        StateDirectoryMode = "0770";

        Restart = "on-failure";
        RestartSec = "5s";

        # Hardening
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        SystemCallFilter = "@system-service";
      };
    };
  };
}
