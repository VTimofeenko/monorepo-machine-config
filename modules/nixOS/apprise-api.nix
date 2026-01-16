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
  cfg = config.services.apprise-api;

  # The package installs to /opt/apprise-api
  # The apprise_api python package is inside that directory.
  # We need to add that directory to PYTHONPATH so `core` can be imported.
  pkg = cfg.package;
  appDir = "${pkg}/opt/apprise-api/apprise_api";
  pythonPath = pkg.pythonPath; # From passthru in package.nix

in
{
  options.services.apprise-api = {
    enable = mkEnableOption "Apprise API service";

    package = mkOption {
      type = types.package;
      default = pkgs.apprise-api;
      defaultText = literalExpression "pkgs.apprise-api";
      description = "The apprise-api package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "apprise";
      description = "User to run the service as. If set to 'apprise', the user will be created automatically. Otherwise, the user must exist.";
    };

    group = mkOption {
      type = types.str;
      default = "apprise";
      description = "Group to run the service as. If set to 'apprise', the group will be created automatically. Otherwise, the group must exist.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to listen on.";
    };

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port to listen on.";
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/apprise-api";
      description = "Directory to store configuration and data.";
    };

    workers = mkOption {
      type = types.int;
      default = 4;
      description = "Number of Gunicorn workers.";
    };

    dynamicUser = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to run as a dynamic user.";
    };

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        APPRISE_STATEFUL_MODE = "simple";
        APPRISE_ADMIN = "yes";
      };
      description = ''
        Extra environment variables to pass to the service.
        See https://github.com/caronc/apprise-api for available options.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users = mkIf (cfg.user == "apprise" && !cfg.dynamicUser) {
      apprise = {
        isSystemUser = true;
        group = cfg.group;
        description = "Apprise API user";
        home = cfg.stateDir;
        createHome = true;
      };
    };

    users.groups = mkIf (cfg.group == "apprise" && !cfg.dynamicUser) {
      apprise = { };
    };

    systemd.services.apprise-api = {
      description = "Apprise API Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        DJANGO_SETTINGS_MODULE = "core.settings";
        APPRISE_CONFIG_DIR = "${cfg.stateDir}/config";
        APPRISE_ATTACH_DIR = "${cfg.stateDir}/attach";
        APPRISE_PLUGIN_PATHS = "${cfg.stateDir}/plugin";
        PYTHONPATH = "${appDir}:${pythonPath}";
      }
      // cfg.settings;

      preStart = ''
        mkdir -p "${cfg.stateDir}/config" "${cfg.stateDir}/attach" "${cfg.stateDir}/plugin"
      '';

      serviceConfig = {
        User = mkIf (!cfg.dynamicUser) cfg.user;
        Group = mkIf (!cfg.dynamicUser) cfg.group;
        DynamicUser = cfg.dynamicUser;
        StateDirectory = mkIf cfg.dynamicUser "apprise-api";
        WorkingDirectory = appDir;
        ExecStart = ''
          ${pkgs.python3Packages.gunicorn}/bin/gunicorn \
            --bind ${cfg.listenAddress}:${toString cfg.port} \
            --workers ${toString cfg.workers} \
            --worker-class gevent \
            core.wsgi:application
        '';

        # Hardening
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ cfg.stateDir ];
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
      };
    };
  };
}
