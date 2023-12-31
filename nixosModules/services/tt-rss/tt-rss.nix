# Module to set up my tiny tiny RSS instance
{ config, ... }:
let
  inherit (config) my-data;
  srvName = "tt-rss";
  service = my-data.lib.getService srvName;

  dbService = my-data.lib.getService "db";
in
{
  /* Secrets */
  age.secrets.tt-rss-db-password = {
    file = my-data.lib.getSrvSecret srvName "dbPassword";
    owner = config.services.tt-rss.user;
  };

  /* Service config */
  services.tt-rss = {
    enable = true;
    virtualHost = service.fqdn;
    singleUserMode = true;
    database = {
      user = "tt_rss";
      port = 5432;
      type = "pgsql";
      name = "tt_rss";
      host = dbService.fqdn;
      # NOTE: For some reason a newline is needed in psql. Use ALTER ROLE with $$PASSWORD\n$$.
      passwordFile = config.age.secrets.tt-rss-db-password.path;
      createLocally = false;
    };
    selfUrlPath = "https://${service.fqdn}";
  };

  /* Wait for VPN to be online before connecting to the database */
  systemd.services.tt-rss =
    let dependency = [ dbService.settings.systemdUnitName ]; in {
      wants = dependency;
      after = dependency;
    };
}
