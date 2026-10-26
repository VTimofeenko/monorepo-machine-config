/**
  Shared blackbox exporter for HTTP health probes of services without metrics.

  Probe scrape jobs come from each service's
  `observability.probes.prometheusImpl` and route through `blackboxAddress`.
*/
{ lib, pkgs, ... }:
let
  inherit (lib.homelab.getSrvLib "prometheus") blackboxAddress;
  addr = lib.splitString ":" blackboxAddress;
in
{
  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = addr |> lib.head;
    port = addr |> lib.last |> lib.toInt;
    configFile = (pkgs.formats.yaml { }).generate "blackbox.yml" {
      modules.http_2xx = {
        prober = "http";
        timeout = "5s";
      };
    };
  };
}
