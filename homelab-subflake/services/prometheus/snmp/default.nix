# Configures snmp exporter on prometheus node to scrape SNMP devices
# - Each device has its own auth (and modules, if not upstream) in `<device>.yml`
# - `common.yml` holds shared modules (if_mib)
# - Each device has its own alerts in `<device>-alerts.nix`
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Only the mikrotik module from upstream prebuilt snmp.yml; the full file collides with local modules
  upstreamMikrotik = pkgs.runCommand "snmp-mikrotik.yml" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
    yq '{"modules": {"mikrotik": .modules.mikrotik}}' ${pkgs.prometheus-snmp-exporter.src}/snmp.yml > $out
  '';

  devices = [
    # Synology NAS. Source: https://colby.gg/posts/2023-10-17-monitoring-synology/
    {
      name = "nas";
      modules = [
        "if_mib"
        "synology"
      ];
      configFiles = [ ./synology.yml ];
      alerts = ./synology-alerts.nix;
    }
    {
      name = "satellite-switch";
      modules = [
        "if_mib"
        "mikrotik"
      ];
      configFiles = [
        ./satellite-switch.yml
        upstreamMikrotik
      ];
      alerts = ./satellite-switch-alerts.nix;
    }
  ];

  # Job name, auth name and host name are all the device name
  mkScrapeConfig = device: {
    job_name = device.name;
    scrape_interval = "30s";
    static_configs = [
      {
        targets = [ (lib.homelab.getHostInNetwork device.name "lan").fqdn ];
        labels = {
          host = device.name;
          resource = "host:${device.name}";
        };
      }
    ];
    metrics_path = "/snmp";
    params = {
      auth = [ device.name ];
      module = device.modules;
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
  };

  mkAlertRules =
    device:
    import device.alerts { selector = ''resource="host:${device.name}"''; }
    |> lib.mapAttrsToList (level: map ((lib.homelab.getSrvLib "prometheus").mkRule device.name level))
    |> lib.flatten;
in
{
  services.prometheus.exporters.snmp = {
    enable = true;
    configurationPath = ./common.yml;
    extraFlags = [
      # To parse passwords
      "--config.expand-environment-variables"
    ]
    ++ (devices |> lib.concatMap (d: d.configFiles) |> map (f: "--config.file=${f}"));
  };

  # Strictly speaking, LoadCredential would be better but then prometheus-snmp-exporter would need to be wrapped to read from CREDENTIALS_DIRECTORY in an overlay and that's a bit overkill for me.
  systemd.services.prometheus-snmp-exporter.serviceConfig.EnvironmentFile = [
    config.age.secrets."prometheus-env-secrets".path
  ];

  services.prometheus.ruleFiles = [
    (pkgs.writeText "snmp-devices.rules.json" (
      {
        groups = devices |> map (d: {
          name = "snmp-${d.name}";
          rules = mkAlertRules d;
        });
      }
      |> builtins.toJSON
    ))
  ];

  services.prometheus.scrapeConfigs = (map mkScrapeConfig devices) ++ [
    {
      job_name = "snmp_exporter";
      static_configs = [ { targets = [ "localhost:9116" ]; } ];
    }
  ];
}
