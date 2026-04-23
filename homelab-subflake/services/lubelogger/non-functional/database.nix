{ config, ... }:
{
  # `POSTGRES_CONNECTION` must be the full postgres connection string, e.g.:
  # `Host=<db-fqdn>;Database=lubelogger;Username=lubelogger;Password=<password>`
  services.lubelogger.environmentFile = config.age.secrets.lubelogger-env.path;
}
