{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.frigate-notify;
  format = pkgs.formats.yaml { };
in
{
  options = {
    services.frigate-notify = {
      enable = lib.mkEnableOption "Frigate Notify";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.frigate-notify;
        description = "The frigate-notify package to use.";
      };

      settings = lib.mkOption {
        type = format.type;
        default = { };
        description = ''
          Configuration for frigate-notify.
          See <https://github.com/0x2142/frigate-notify> for details.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.frigate-notify = {
      description = "Frigate Notify Service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/frigate-notify -c ${format.generate "config.yml" cfg.settings}";
        Restart = "always";

        DynamicUser = true;
        StateDirectory = "frigate-notify";
        WorkingDirectory = "/var/lib/frigate-notify";

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
  };
}
