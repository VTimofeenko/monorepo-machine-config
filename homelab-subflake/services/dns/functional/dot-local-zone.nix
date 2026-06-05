/**
  Configures `.local` zone to not recurse.
*/
{
  services.unbound.settings.server.local-zone = [ "local. static" ];
}
