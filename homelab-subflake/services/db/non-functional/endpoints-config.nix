endpoints:
{ ... }:
{
  services.prometheus.exporters.postgres.port = endpoints.metrics.port;
  # Database will listen on all IPs, using `./firewall.nix` and ACL (`pg_hba`) to limit clients
  # TODO: move ACL to dedicated file?
}
