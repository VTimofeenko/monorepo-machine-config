{ lib, serviceName, ... }:
{
  module = ./snapmaker.nix;

  # Both endpoints are nginx relays on the service host towards the printer in
  # the IoT VLAN. The printer itself is only reachable from this host.
  endpoints = {
    web = {
      port = 8767;
      protocol = "https";
    };
    metrics = {
      port = 9101;
      protocol = "tcp";
    };
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  sslProxyConfig = import ./non-functional/ssl.nix { inherit serviceName; };

  # prometheus-klipper-exporter is a multi-target exporter, the printer's own
  # Moonraker is the target. `modules` must be repeated, not comma-separated.
  # `temperature` (all sensors from the temperature store, incl. extruder1-3)
  # is a separate exporter: it emits the same names as `printer_objects` for
  # extruder/heater_bed, and duplicates fail the whole scrape.
  observability.metrics =
    let
      mkProbe = modules: {
        endpoint = "metrics";
        path = "/probe?target=127.0.0.1:7125" + lib.concatMapStrings (it: "&modules=${it}") modules;
      };
    in
    {
      main = mkProbe [
        "printer_objects"
        "history"
        "process_stats"
        "directory_info"
      ];
      temperature = mkProbe [ "temperature" ];
    };

  dashboard = {
    category = "Home";
    links = [
      {
        name = "Snapmaker U1";
        icon = "fluidd";
        description = "Multi-color 3D printer";
      }
    ];
  };

  roamNodes = [
    "2b38073b-3e7d-4546-baf0-7207fe0010fb" # Snapmaker U1
  ];
}
