/**
  Configures long lease times and renew times. I can always purge everything by
  hand if necessary.

  This will prevent spam in logs.

  Source:
  https://kea.readthedocs.io/en/latest/arm/config-templates.html#template-home-network-of-a-power-user
*/
{
  services.kea.dhcp4.settings = {
    valid-lifetime = 43200; # Leases will be valid for 12h
    renew-timer = 21600; # Clients should renew every 6h
    rebind-timer = 32400; # Clients should start looking for other servers after 9h
  };
}
