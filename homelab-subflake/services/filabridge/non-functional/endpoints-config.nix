endpoints:
{ ... }:
{
  # Binds all interfaces regardless; the firewall only admits the SSL proxy
  services.filabridge = {
    inherit (endpoints.web) port;
  };
}
