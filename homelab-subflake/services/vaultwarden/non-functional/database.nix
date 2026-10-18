{ config, ... }:
{
  services.vaultwarden.dbBackend = "postgresql";

  # Provides `DATABASE_URL` (embeds the DB password)
  services.vaultwarden.environmentFile = config.age.secrets.vaultwarden-env.path;
}
