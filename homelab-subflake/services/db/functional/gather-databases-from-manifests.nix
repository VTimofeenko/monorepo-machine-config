/**
  Provisions PostgreSQL users and databases for all services that declare
  `database.create = true` in their manifest.

  Uses `ensureUsers` with `ensureDBOwnership` — passwords are managed out of
  band per service.
*/
{ lib, ... }:
{
  imports =
    lib.homelab.getManifests
    |> lib.filterAttrs (_: m: m.database != null && m.database.create)
    |> lib.mapAttrsToList (srvName: _: {
      services.postgresql = {
        ensureDatabases = [ srvName ];
        ensureUsers = [
          {
            name = srvName;
            ensureDBOwnership = true;
          }
        ];
      };
    });
}
