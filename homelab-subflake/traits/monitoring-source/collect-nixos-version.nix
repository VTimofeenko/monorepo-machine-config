{ pkgs, config, ... }:
{
  systemd = {
    services.prometheus-node-export-nixos-version = {
      description = "Get the value of nixos-version file for prometheus";
      script = ''
        cd $RUNTIME_DIRECTORY
        NIXOS_VERSION=$(cat /run/current-system/nixos-version)
        VERSION_PARSED=(''${NIXOS_VERSION//-/ })

        if [[ ''${VERSION_PARSED[1]} =~ "dirty" ]]; then
          NIXOS_VERSION_DIRTY=1
        else
          NIXOS_VERSION_DIRTY=0
        fi

        # Strings are not a type in prometheus, so passing this as a label
        echo "nixos_version_info{version=\"''${VERSION_PARSED[0]}\"} $NIXOS_VERSION_DIRTY" > nixos_version.prom
      '';
      path = [ pkgs.coreutils ];
      serviceConfig = {
        Type = "oneshot";
        RuntimeDirectory = [ "node_exporter_text" ];
        inherit (config.systemd.services.prometheus-node-exporter.serviceConfig) User;
        RuntimeDirectoryPreserve = true;
        # Hardening
        PrivateTmp = true;
        WorkingDirectory = "/tmp";
        DynamicUser = false;
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [ ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };

    timers.prometheus-node-export-nixos-version = {
      timerConfig = {
        OnCalendar = "*:0/1";
        Persistent = true;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
