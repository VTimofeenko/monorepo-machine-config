{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.homelab) getServiceFqdn;
  srvName = "nextcloud";
in
{
  # Service configuration
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = getServiceFqdn srvName;

    configureRedis = true;

    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
    };

    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = getServiceFqdn "db";
      dbname = "nextcloud";
      dbpassFile = config.age.secrets.nextcloud-db-password.path;
      adminuser = "root";
      adminpassFile = config.age.secrets.nextcloud-admin-password.path;
    };
    settings = {
      allow_local_remote_servers = true;
      overwriteprotocol = "https";
      trusted_proxies = lib.homelab.getSSLProxyIPs;
      maintenance_window_start = 10; # In UTC, = 2 AM PST
      default_phone_region = "US";
    };

    secretFile = config.age.secrets.nextcloud-secrets.path;
  };

  imports = lib.localLib.mkImportsFromDir ./functional;

}
