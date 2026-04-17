# TODO: Allow only specific clients in, based on service dependencies
{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [ config.services.postgresql.settings.port ];
}
