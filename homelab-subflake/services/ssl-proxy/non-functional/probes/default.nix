/**
  Implements `ssl_exporter` probe
  Ref:
  - https://github.com/ribbybibby/ssl_exporter
*/
{ lib, ... }:
let
  port = 9219; # TODO: Grab from own manifest
in
{
  services.prometheus.exporters.ssl_exporter = {
    enable = true;
    inherit port;
  };

  # TODO: use `srv:prometheus` `srvLib` to generate this
  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" ip saddr ${
      "prometheus" |> lib.homelab.getServiceInnerIP
    } tcp dport ${port |> toString} accept comment "Allow prometheus to scrape ssl probes"
  '';

  imports = [ ./impl.nix ];
}
