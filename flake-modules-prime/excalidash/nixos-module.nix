/**
  `services.excalidash`: self-hosted Excalidraw dashboard.

  - Module specific frontend uses nginx (similar to `frigate` module) to route
    to backend and frontend as SPA.
  - Implementation tries to be as systemd compatible as possible. The
    `docker-compose` files were taken as the source.
  - JavaScript bits were inspired by `linkwarden` module in nixpkgs
  - `database` is a `types.attrTag` (`database.postgresql.*` or
    `database.sqlite.*`, mutually exclusive by construction) — see
    `../packages/excalidash-backend-sqlite.nix`.

  TODO:
  - (maybe) drop bundled nginx?
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.excalidash;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkPackageOption
    types
    ;
in
{
  options.services.excalidash = {
    enable = mkEnableOption "ExcaliDash — self-hosted Excalidraw dashboard";

    backendPackage = mkOption {
      type = types.package;
      default = if cfg.database ? sqlite then pkgs.excalidash-backend-sqlite else pkgs.excalidash-backend;
      defaultText = lib.literalExpression ''
        if config.services.excalidash.database ? sqlite
        then pkgs.excalidash-backend-sqlite
        else pkgs.excalidash-backend
      '';
      description = ''
        Which backend build to run. Prisma bakes its datasource provider in
        at build time (not runtime-switchable), so this must match whichever
        `database` tag is set — the default already does this automatically;
        only override if supplying a differently-built package entirely.
      '';
    };
    frontendPackage = mkPackageOption pkgs "excalidash-frontend" { };

    listenHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address the local nginx (serving the SPA and proxying to the backend) listens on.";
    };

    listenPort = mkOption {
      type = types.port;
      default = 6767;
      description = "Port the local nginx listens on.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open `listenPort` in the firewall.";
    };

    authMode = mkOption {
      type = types.str;
      default = "local";
      description = ''
        ExcaliDash `AUTH_MODE` — one of `local`, `oidc`, `hybrid`,
        `oidc_enforced`, or `disabled`. `disabled` turns off authentication
        entirely (single shared user, no login) — do not use on anything
        network-reachable by untrusted clients.
      '';
    };

    trustProxy = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to trust `X-Forwarded-*` headers. Only enable if something
        upstream of the local nginx (an external reverse proxy) sanitizes
        them — otherwise this lets clients spoof their own origin/proto.
      '';
    };

    # A tagged union, not a flat `type` enum + "only used when..." fields:
    # Prisma generates a provider-specific client (not runtime-switchable),
    # so postgresql's and sqlite's settings are genuinely mutually exclusive
    # — this makes that a type error (`defined both as postgresql and
    # sqlite`) instead of silently-dead config. Set exactly one:
    # `database.postgresql.host = ...;` or `database.sqlite.path = ...;`.
    database = mkOption {
      type = types.attrTag {
        postgresql = mkOption {
          description = "Run against Postgres.";
          type = types.submodule {
            options = {
              host = mkOption {
                type = types.str;
                default = "127.0.0.1";
                description = "Postgres host.";
              };
              port = mkOption {
                type = types.port;
                default = 5432;
                description = "Postgres port.";
              };
              name = mkOption {
                type = types.str;
                default = "excalidash";
                description = "Postgres database name.";
              };
              user = mkOption {
                type = types.str;
                default = "excalidash";
                description = "Postgres role name.";
              };
              passwordFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  File containing the Postgres role's password. Leave unset
                  only for a Postgres instance configured for passwordless
                  (trust/peer) auth for this role — never leave unset
                  against a real password-auth instance.
                '';
              };
            };
          };
        };

        sqlite = mkOption {
          description = "Run against a local sqlite file.";
          type = types.submodule {
            options = {
              path = mkOption {
                type = types.path;
                default = "/var/lib/excalidash/excalidash.db";
                description = ''
                  Where the sqlite database file lives. The default is under
                  this unit's own `StateDirectory`, which is the only sane
                  choice unless you have a specific reason to put it
                  elsewhere — it needs to be somewhere
                  `excalidash-backend`'s `DynamicUser` can read and write.
                '';
              };
            };
          };
        };
      };
      default.postgresql = { };
      description = "Which database to run against, and its connection details.";
    };

    jwtSecretFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        File containing JWT_SECRET. Leave unset to auto-generate and persist
        one under this service's StateDirectory on first boot.
      '';
    };

    csrfSecretFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        File containing CSRF_SECRET. Leave unset to auto-generate and
        persist one under this service's StateDirectory on first boot.
      '';
    };

    frontendUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://excalidash.example.com";
      description = ''
        The externally-reachable origin(s) this is actually served at
        (`FRONTEND_URL`), comma-separated if there's more than one. The
        backend rejects any request whose `Origin`/`Referer` doesn't match
        one of these as a CSRF failure — in production mode (always, here)
        it does *not* fall back to allowing any `localhost`/`127.0.0.1`
        origin, only its own unset-default of exactly
        `http://localhost:6767`. Leave unset only if this is genuinely
        reachable at that exact origin (e.g. `listenHost = "127.0.0.1";
        listenPort = 6767;` with nothing forwarding/proxying a different
        host or port in front of it) — set it explicitly for anything
        behind a reverse proxy, a different port, or port-forwarding (a
        demo VM, for instance).
      '';
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra plain (non-secret) environment variables for the backend, e.g. OIDC_ISSUER_URL.";
    };

    secretFiles = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = ''
        Extra secret environment variables for the backend, as
        `{ ENV_VAR_NAME = <path to a file containing the raw value>; }`
        (e.g. `OIDC_CLIENT_SECRET`, S3 credentials).
      '';
    };

    backendPort = mkOption {
      type = types.port;
      default = 8080;
      example = 8001;
      description = "The network port the backend service should listen on.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.excalidash-backend =
      let
        # Every secret this unit needs, keyed by the systemd credential id
        # `LoadCredential` will expose it under ($CREDENTIALS_DIRECTORY/<id>).
        externalSecrets =
          cfg.secretFiles
          // lib.optionalAttrs (
            cfg.database ? postgresql && cfg.database.postgresql.passwordFile != null
          ) { db-password = cfg.database.postgresql.passwordFile; }
          // lib.optionalAttrs (cfg.jwtSecretFile != null) { jwt-secret = cfg.jwtSecretFile; }
          // lib.optionalAttrs (cfg.csrfSecretFile != null) { csrf-secret = cfg.csrfSecretFile; };

        renderEnvScript = pkgs.writeShellScript "excalidash-render-env" ''
          set -euo pipefail
          umask 077

          # JWT/CSRF: use the externally-provided secret if given, else
          # generate-once-and-persist under our own StateDirectory (matches
          # upstream docker-entrypoint.sh's own zero-config first-run path).
          ${lib.concatMapStringsSep "\n" (
            name:
            ''
              if [ -f "''${CREDENTIALS_DIRECTORY:-/nonexistent}/${name}" ]; then
                ${lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] name)}="$(<"''${CREDENTIALS_DIRECTORY}/${name}")"
              elif [ -f "''${STATE_DIRECTORY}/.${name}" ]; then
                ${lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] name)}="$(<"''${STATE_DIRECTORY}/.${name}")"
              else
                ${lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] name)}="$(${lib.getExe' pkgs.openssl "openssl"} rand -hex 32)"
                printf '%s' "''${${lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] name)}}" > "''${STATE_DIRECTORY}/.${name}"
                chmod 600 "''${STATE_DIRECTORY}/.${name}"
              fi
            ''
          ) [ "jwt-secret" "csrf-secret" ]}

          {
            printf 'JWT_SECRET=%s\n' "$JWT_SECRET"
            printf 'CSRF_SECRET=%s\n' "$CSRF_SECRET"
            # Points excalidash-backend's uploads staging dir at our own
            # StateDirectory instead of it defaulting to a relative path
            # next to the (read-only, Nix-store) source — see
            # ../packages/excalidash-backend.nix's postPatch.
            printf 'XDG_DATA_HOME=%s\n' "$STATE_DIRECTORY"
            ${lib.optionalString (cfg.database ? sqlite) ''
              printf 'DATABASE_URL=file:${cfg.database.sqlite.path}\n'
            ''}
            ${lib.optionalString (cfg.database ? postgresql && cfg.database.postgresql.passwordFile != null) ''
              DB_PASSWORD="$(<"''${CREDENTIALS_DIRECTORY}/db-password")"
              printf 'DATABASE_URL=postgresql://${cfg.database.postgresql.user}:%s@${cfg.database.postgresql.host}:${toString cfg.database.postgresql.port}/${cfg.database.postgresql.name}\n' "$DB_PASSWORD"
            ''}
            ${lib.optionalString (cfg.database ? postgresql && cfg.database.postgresql.passwordFile == null) ''
              printf 'DATABASE_URL=postgresql://${cfg.database.postgresql.user}@${cfg.database.postgresql.host}:${toString cfg.database.postgresql.port}/${cfg.database.postgresql.name}\n'
            ''}
            ${lib.concatMapStringsSep "\n" (name: ''
              printf '${name}=%s\n' "$(<"''${CREDENTIALS_DIRECTORY}/${name}")"
            '') (lib.attrNames cfg.secretFiles)}
          } > "''${RUNTIME_DIRECTORY}/env"
        '';
      in
      {
        description = "ExcaliDash backend";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
        ]
        ++ lib.optional (
          cfg.database ? postgresql && cfg.database.postgresql.host == "127.0.0.1"
        ) "postgresql.service";

        environment = cfg.environment // lib.optionalAttrs (cfg.frontendUrl != null) {
          FRONTEND_URL = cfg.frontendUrl;
        } // {
          NODE_ENV = "production";
          PORT = toString cfg.backendPort;
          AUTH_MODE = cfg.authMode;
          TRUST_PROXY = lib.boolToString cfg.trustProxy;
          DATABASE_PROVIDER = if cfg.database ? sqlite then "sqlite" else "postgresql";
          # `DynamicUser` has no `passwd` entry, so Node's `os.homedir()` (used by
          # Prisma's CLI, e.g. via `tempy`, during `excalidash-migrate`)
          # fails with `uv_os_homedir returned ENOENT` unless $HOME is set.
          HOME = "/var/lib/excalidash";
        };

        serviceConfig = {
          DynamicUser = true;
          RuntimeDirectory = "excalidash";
          StateDirectory = "excalidash";

          LoadCredential = lib.mapAttrsToList (name: path: "${name}:${path}") externalSecrets;

          # Reread per Exec* invocation, so the first (which renders it)
          # runs fine before the file exists — see `renderEnvScript` above.
          EnvironmentFile = "-/run/excalidash/env";

          ExecStartPre = [
            renderEnvScript
            (lib.getExe' cfg.backendPackage "excalidash-migrate")
          ];
          ExecStart = lib.getExe' cfg.backendPackage "excalidash-server";

          Restart = "on-failure";

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

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;

      virtualHosts."excalidash" = {
        listen = [
          {
            addr = cfg.listenHost;
            port = cfg.listenPort;
          }
        ];

        root = cfg.frontendPackage;

        locations."/" = {
          tryFiles = "$uri /index.html";
        };

        locations."/api/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.backendPort}/";
        };

        locations."/socket.io/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.backendPort}/socket.io/";
          proxyWebsockets = true;
        };
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.listenPort ];
  };
}
