{ port, ... }:
{
  lib,
  self,
  config,
  pkgs,
  ...
}:
{
  age.secrets.db-exporter-password.owner = config.services.prometheus.exporters.postgres.user;

  services.prometheus.exporters.postgres = {
    enable = true;
    inherit port;
    openFirewall = false;
    environmentFile = pkgs.writeTextFile {
      name = "postgres-exporter.env";
      text = ''
        DATA_SOURCE_URI=localhost:5432/postgres?sslmode=disable
        DATA_SOURCE_USER=postgres_exporter
        DATA_SOURCE_PASS_FILE=${config.age.secrets.db-exporter-password.path}
      '';
    };
  };

  # Force disable DATA_SOURCE_NAME, using DATA_SOURCE_URI
  systemd.services.prometheus-postgres-exporter.environment = {
    DATA_SOURCE_NAME = lib.mkForce "";
  };

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib port;
    })
  ];
}
