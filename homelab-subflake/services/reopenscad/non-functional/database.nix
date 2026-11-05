{ config, lib, ... }:
{
  services.reopenscad.database = {
    enable = true;
    createLocally = false;
    # sslmode=require: the db host's wildcard cert is verified against this FQDN
    url = "host=${
      "db" |> lib.homelab.getServiceFqdn
    } user=reopenscad dbname=reopenscad sslmode=require";
    # Read by root through LoadCredential, so no owner is needed for the DynamicUser
    passwordFile = config.age.secrets.reopenscad-db-password.path;
  };
}
