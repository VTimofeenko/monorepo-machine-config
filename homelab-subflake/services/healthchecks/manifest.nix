{ lib, serviceName, ... }:
{
  module = ./healthchecks.nix;

  endpoints.web = {
    port = 8000;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = {
    # TODO: this URL points to the "mostly backups" project in `healthchecks`. While important, it's not proper "service is up" monitoring.
    metrics.main.path = lib.homelab.getServiceConfig serviceName |> (cfg: cfg.metricsURL);
    alerts.prometheusImpl = ./non-functional/alerts.nix;
  };

  # Backups disabled - FIXME: enable after migration of cerium
  # ```
  # backups = {
  #   paths = [ "/var/lib/healthchecks" ];
  #   impl = { lib, ... }:
  #     lib.localLib.mkBkp {
  #       paths = [ "/var/lib/healthchecks" ];
  #       inherit serviceName;
  #       localOnly = true;
  #     };
  # };
  # ```

  dashboard = {
    category = "Admin";
    links = [
      {
        description = "Periodic ping reporting (backups, network check, etc.)";
        icon = "healthchecks";
        name = "Healthchecks";
      }
    ];
  };
}
