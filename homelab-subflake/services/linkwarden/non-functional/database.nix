{ config, lib, ... }:
{
  services.linkwarden.database = {
    createLocally = lib.mkForce false;
    host = "maindb.${lib.homelab.getSettings.publicDomainName}"; # TODO: `prj:move-db`
  };

  services.linkwarden.secretFiles.POSTGRES_PASSWORD = config.age.secrets.linkwarden-db-password.path;
}
