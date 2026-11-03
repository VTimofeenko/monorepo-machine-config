/**
  Aggregate firewall packet logs from `srv:gateway` (ulogd's text lines).
*/
{ lib, ... }:
let
  port = (lib.homelab.getManifest "log-concentrator").endpoints.firewall-logs.port;
  gatewayIP =
    "gateway" |> lib.homelab.getServiceHost |> lib.flip lib.homelab.getHostIpInNetwork "backbone-inner";
in
{
  services.vector.settings.sources.firewall-log-concentrator = {
    type = "vector";
    address = "0.0.0.0:${port |> toString}";
    # See the private mixin for the write portion
  };

  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" ip saddr ${gatewayIP} tcp dport ${port |> toString} accept comment "Firewall logs from the gateway"
  '';
}
