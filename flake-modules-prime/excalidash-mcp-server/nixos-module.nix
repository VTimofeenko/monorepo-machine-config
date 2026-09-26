/**
  `services.excalidash-mcp-server`: runs `excalidash-mcp-server` as an
  always-on MCP endpoint over streamable-http, so it's reachable from any
  session/client rather than needing a local `claude mcp add --transport
  stdio` per machine. Modeled on `../prometheus-mcp-server/nixos-module.nix`.

  The API key is a secret — never put it in `extraEnv` (that lands in the
  Nix store / this public repo's evaluated closure); use `environmentFile`.
*/
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.excalidash-mcp-server;
in
{
  options.services.excalidash-mcp-server = {
    enable = lib.mkEnableOption "ExcaliDash MCP Server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.excalidash-mcp-server;
      defaultText = lib.literalExpression "pkgs.excalidash-mcp-server";
      description = "The excalidash-mcp-server package to use.";
    };

    excalidashUrl = lib.mkOption {
      type = lib.types.str;
      description = "Base URL of the ExcaliDash instance's API (EXCALIDASH_URL), e.g. https://excalidash.example.com/api.";
      example = "https://excalidash.example.com/api";
    };

    transport = lib.mkOption {
      type = lib.types.enum [
        "stdio"
        "sse"
        "streamable-http"
      ];
      default = "streamable-http";
      description = "MCP transport type (EXCALIDASH_MCP_TRANSPORT).";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind when transport is http-based (EXCALIDASH_MCP_HOST).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8765;
      description = "Port to bind when transport is http-based (EXCALIDASH_MCP_PORT).";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the API key, e.g.:
          EXCALIDASH_API_KEY=exd_...
        Generate the key in ExcaliDash under Settings -> API Keys, with at
        least the `drawings:read`, `drawings:write` and `collections:read`
        scopes (add `collections:write` too if the agent should be able to
        create new collections).
      '';
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional non-secret environment variables to pass to the service.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.excalidash-mcp-server = {
      description = "ExcaliDash MCP Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        EXCALIDASH_URL = cfg.excalidashUrl;
        EXCALIDASH_MCP_TRANSPORT = cfg.transport;
        EXCALIDASH_MCP_HOST = cfg.listenAddress;
        EXCALIDASH_MCP_PORT = toString cfg.port;
      }
      // cfg.extraEnv;

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";

        DynamicUser = true;

        EnvironmentFile = cfg.environmentFile;

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
      };
    };
  };
}
