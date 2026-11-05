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
    types
    mkEnableOption
    literalExpression
    ;
  cfg = config.services.reopenscad;
  # Peer auth over the unix socket: the role name matches the service user
  localDatabaseUrl = "host=/run/postgresql user=reopenscad dbname=reopenscad";
  isLoopback = builtins.elem cfg.listenAddress [
    "127.0.0.1"
    "localhost"
    "::1"
  ];
  dbLocal = cfg.database.enable && cfg.database.createLocally;
  withPassword = cfg.database.enable && cfg.database.passwordFile != null;
in
{
  options.services.reopenscad = {
    enable = mkEnableOption "ReOpenSCAD browser workbench";

    package = mkOption {
      type = types.package;
      default =
        if cfg.database.enable then pkgs.reopenscad.override { withPostgres = true; } else pkgs.reopenscad;
      defaultText = literalExpression ''
        if config.services.reopenscad.database.enable
        then pkgs.reopenscad.override { withPostgres = true; }
        else pkgs.reopenscad
      '';
      description = "The reopenscad package to use. Postgres storage needs one built with `withPostgres`.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to listen on.";
    };

    port = mkOption {
      type = types.port;
      default = 5180;
      description = "Port to listen on.";
    };

    publicOrigin = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://reopenscad.example.com";
      description = ''
        Origin the server is reached at. Every request's Host header is checked
        against it, so it is needed behind a reverse proxy, and required when
        listening on a non-loopback address.
      '';
    };

    database = {
      enable = mkEnableOption "Postgres design storage instead of files in /var/lib/reopenscad";

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to create the database and role on the local Postgres server.";
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = if cfg.database.createLocally then localDatabaseUrl else null;
        defaultText = literalExpression ''
          if createLocally then "${localDatabaseUrl}" else null
        '';
        example = "host=db.example.com user=reopenscad dbname=reopenscad sslmode=require";
        description = ''
          libpq-style connection string, passed as `DATABASE_URL`. TCP connections use TLS.
          It ends up in the world-readable unit file, so keep the password in `passwordFile`.
        '';
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "File with the database password, appended to `url` at service start.";
      };
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/reopenscad.env";
      description = "Environment file for secrets, e.g. `DATABASE_URL=...` with a password.";
    };

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        REOPENSCAD_TRUSTED_PROXY_HOPS = "1";
        REOPENSCAD_MAX_CONCURRENT_JOBS = "2";
      };
      description = ''
        Extra environment variables for the server.
        See https://github.com/Matvey-Kuk/reopenscad/blob/main/web/README.md.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = isLoopback || cfg.publicOrigin != null;
        message = "services.reopenscad.publicOrigin must be set when listenAddress is not loopback.";
      }
      {
        assertion = cfg.database.enable -> (cfg.database.url != null || cfg.environmentFile != null);
        message = "services.reopenscad.database needs either database.url or DATABASE_URL in environmentFile.";
      }
      {
        assertion = cfg.database.passwordFile != null -> cfg.database.url != null;
        message = "services.reopenscad.database.passwordFile needs database.url to append to.";
      }
    ];

    services.postgresql = mkIf dbLocal {
      enable = true;
      ensureDatabases = [ "reopenscad" ];
      ensureUsers = [
        {
          name = "reopenscad";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.reopenscad = {
      description = "ReOpenSCAD";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ lib.optional dbLocal "postgresql.target";
      requires = lib.optional dbLocal "postgresql.target";

      environment = {
        HOST = cfg.listenAddress;
        PORT = toString cfg.port;
      }
      // lib.optionalAttrs (!cfg.database.enable) {
        REOPENSCAD_DATA_DIR = "/var/lib/reopenscad";
      }
      // lib.optionalAttrs (cfg.database.enable && cfg.database.url != null && !withPassword) {
        DATABASE_URL = cfg.database.url;
      }
      // lib.optionalAttrs (cfg.publicOrigin != null) {
        REOPENSCAD_PUBLIC_ORIGIN = cfg.publicOrigin;
      }
      // cfg.settings;

      serviceConfig = {
        ExecStart =
          if withPassword then
            # The driver reads no PGPASSWORD/.pgpass, so the password has to go into the
            # connection string itself; `$(<file)` drops the trailing newline
            pkgs.writeShellScript "reopenscad-start" ''
              password="$(<"$CREDENTIALS_DIRECTORY/db-password")"
              password="''${password//\\/\\\\}"
              password="''${password//\'/\\\'}"
              export DATABASE_URL="${cfg.database.url} password='$password'"
              exec ${lib.getExe cfg.package}
            ''
          else
            lib.getExe cfg.package;
        LoadCredential = mkIf withPassword [ "db-password:${cfg.database.passwordFile}" ];
        DynamicUser = true;
        User = "reopenscad";
        StateDirectory = mkIf (!cfg.database.enable) "reopenscad";
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
        Restart = "on-failure";

        # Hardening
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        UMask = "0077";
      };
    };
  };
}
