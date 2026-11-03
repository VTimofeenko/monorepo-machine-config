{ ... }:
{
  module = ./alertmanager.nix;

  endpoints.web = {
    port = 9093;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  firewall = ./non-functional/firewall.nix;

  # TODO: ACL to only allow humans & `srv:grafana`

  # TODO: implement "watch the watcher". Periodic pings into `srv:healthchecks`?
  # observability = { };

  dashboard = {
    category = "Admin";
    links = [
      {
        icon = "alertmanager";
        name = "Alert manager";
      }
    ];
  };

  observability.logging.units = [
    "alertmanager.service"
    "alertmanager-ntfy.service"
  ];
}
