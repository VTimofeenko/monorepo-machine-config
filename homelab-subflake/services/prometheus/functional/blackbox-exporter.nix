/**
  Shared blackbox exporter for HTTP health probes of services without metrics.

  Probe scrape jobs come from each service's
  `observability.probes.prometheusImpl` and route through `blackboxAddress`.
  A probe that needs its own prober settings (e.g. a Host header) adds a
  module to `services.homelab.blackbox.modules` from that same file.
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.homelab.getSrvLib "prometheus") blackboxAddress;
  addr = lib.splitString ":" blackboxAddress;
in
{
  options.services.homelab.blackbox.modules = lib.mkOption {
    type = lib.types.attrsOf (pkgs.formats.yaml { }).type;
    description = "Blackbox exporter modules, selected by a probe job's `params.module`.";
  };

  config.services.homelab.blackbox.modules.http_2xx = {
    prober = "http";
    timeout = "5s";
  };

  config.services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = addr |> lib.head;
    port = addr |> lib.last |> lib.toInt;
    configFile = (pkgs.formats.yaml { }).generate "blackbox.yml" {
      inherit (config.services.homelab.blackbox) modules;
    };
  };
}
