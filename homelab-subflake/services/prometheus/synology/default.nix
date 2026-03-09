# Configures snmp exporter to run on prometheus node that gets snmp values from synology
{ config, lib, ... }:
{
  services.prometheus.exporters.snmp = {
    enable = true;
    configurationPath = ./synology.yml;
    # To parse passwords
    extraFlags = [ "--config.expand-environment-variables" ];
  };

  # Secrets
  age.secrets."prometheus-synology-secret".file = lib.homelab.getSrvSecret "prometheus" "synology-snmp-creds";

  # Strictly speaking, LoadCredential would be better but then prometheus-snmp-exporter would need to be wrapped to read from CREDENTIALS_DIRECTORY in an overlay and that's a bit overkill for me.
  systemd.services.prometheus-snmp-exporter.serviceConfig.EnvironmentFile = [
    config.age.secrets."prometheus-synology-secret".path
  ];

  # Source:
  # https://colby.gg/posts/2023-10-17-monitoring-synology/
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nas";
      scrape_interval = "30s";
      static_configs = [ { targets = [ (lib.homelab.getHostInNetwork "nas" "lan").fqdn ]; } ];
      metrics_path = "/snmp";
      params = {
        auth = [ "synology" ];
        module = [
          "if_mib"
          "synology"
        ];
      };
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = "localhost:9116";
        }
      ];
    }
    {
      job_name = "snmp_exporter";
      static_configs = [ { targets = [ "localhost:9116" ]; } ];
    }
  ];
}
