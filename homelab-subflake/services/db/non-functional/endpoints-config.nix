endpoints:
{ lib, ... }:
{
  services.prometheus.exporters.postgres.port = endpoints.metrics.port;

  services.postgresql.settings.listen_addresses = lib.mkForce (
    lib.concatStringsSep ", " (
      (map lib.homelab.getOwnIpInNetwork [
        "mgmt"
        "db" # TODO: remove this when decommissioning `db` network
        "backbone-inner"
      ])
      ++ [ "127.0.0.1" ]
    )
  );
}
