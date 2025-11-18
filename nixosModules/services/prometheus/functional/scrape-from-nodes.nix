/**
  Implement targets for nodes
*/
{ lib, config, ... }:
{
  services.prometheus.scrapeConfigs =
    lib.homelab.getServiceConfig "prometheus"
    # Grab list of default exporters
    |> builtins.getAttr "exporters"
    # Change the list for easy access later
    |> map (it: {
      exporterName = it;
      # This relies on:
      # - Single port for a scraper
      # - Port is default (expressed through `config` reference)
      exporterPort = config.services.prometheus.exporters.${it}.port;
    })
    # Construct a `scrapeConfig`
    |> map (it: {
      job_name = it.exporterName;
      scrape_interval = "30s";
      static_configs =
        lib.homelab.getService "monitoring-source"
        |> builtins.getAttr "onHosts"
        |> map (nodeName: {
          targets =
            let
              hostName = lib.homelab.getHostIpInNetwork nodeName "backbone-inner";
            in
            [
              "${hostName}:${it.exporterPort |> toString}"
            ];
          labels.alias = "${nodeName}.home.arpa";
        });
    });
}
