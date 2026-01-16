/**
  Sets up Gitea to use the Postgres instance.
*/
{ config, lib, ... }:
{
  services.gitea.database = {
    user = "gitea";
    type = "postgres";
    passwordFile = config.age.secrets.gitea-db-password.path;
    host = "db" |> lib.homelab.getServiceFqdn;
    createDatabase = false; # Otherwise, a local Postgres instance will be created
  };

  age.secrets.gitea-db-password.owner = config.services.gitea.user;
}
