/**
  Module for youtube-rss-server: YouTube channel/playlist feeds via the YouTube
  Data API, as a drop-in for `youtube.com/feeds/videos.xml`.

  Stateless; caches are in memory. All configuration is environment variables,
  see upstream README.
*/
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.youtube-rss-server;
  inherit (lib) types mkOption;
in
{
  options.services.youtube-rss-server = {
    enable = lib.mkEnableOption "youtube-rss-server";

    package = lib.mkPackageOption pkgs "youtube-rss-server" { };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to listen on.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to listen on.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        File with `API_KEY=<YouTube Data API key>`. Without it the server falls
        back to Application Default Credentials.
      '';
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        MAX_RESULTS = "30";
        ITEMS_CACHE_TTL = "1h";
      };
      description = "Extra environment variables passed to youtube-rss-server.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.youtube-rss-server = {
      description = "youtube-rss-server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      environment = {
        LISTEN_ADDR = "${cfg.listenAddress}:${toString cfg.port}";
      }
      // cfg.environment;

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
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
        SystemCallFilter = [
          "@system-service"
          "~@privileged @resources"
        ];
        UMask = "0077";
      };
    };
  };
}
