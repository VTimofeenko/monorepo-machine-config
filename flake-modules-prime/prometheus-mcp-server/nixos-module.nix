{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.prometheus-mcp-server;
in
{
  options.services.prometheus-mcp-server = {
    enable = lib.mkEnableOption "Prometheus MCP Server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.prometheus-mcp-server;
      defaultText = lib.literalExpression "pkgs.prometheus-mcp-server";
      description = "The prometheus-mcp-server package to use.";
    };

    prometheusUrl = lib.mkOption {
      type = lib.types.str;
      description = "URL of the Prometheus server (PROMETHEUS_URL).";
      example = "http://prometheus:9090";
    };

    transport = lib.mkOption {
      type = lib.types.enum [
        "stdio"
        "http"
        "sse"
      ];
      default = "http";
      description = "MCP transport type (PROMETHEUS_MCP_SERVER_TRANSPORT).";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP/SSE server (PROMETHEUS_MCP_BIND_HOST).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for the HTTP/SSE server (PROMETHEUS_MCP_BIND_PORT).";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file containing secret environment variables, e.g.:
          PROMETHEUS_TOKEN=...
          PROMETHEUS_USERNAME=...
          PROMETHEUS_PASSWORD=...
      '';
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables to pass to the service.";
      example = {
        PROMETHEUS_URL_SSL_VERIFY = "false";
        TOOL_PREFIX = "my_prometheus";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.prometheus-mcp-server = {
      description = "Prometheus MCP Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        PROMETHEUS_URL = cfg.prometheusUrl;
        PROMETHEUS_MCP_SERVER_TRANSPORT = cfg.transport;
        PROMETHEUS_MCP_BIND_HOST = cfg.listenAddress;
        PROMETHEUS_MCP_BIND_PORT = toString cfg.port;
      }
      // cfg.extraEnv;

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "on-failure";

        DynamicUser = true;

        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
      };
    };
  };
}
