/**
  Aggregate `dnstap` logs from nodes
*/
{ lib, ... }:
let
  dnsIps =
    [
      "dns_1"
      "dns_2"
    ]
    |> map (lib.homelab.getServiceHost)
    |> map (lib.flip (lib.homelab.getHostIpInNetwork "backbone-inner"));

  dnstapPort = 9001;
in
{
  services.vector.settings.sinks.dnstap = {
    type = "vector";
    address = "0.0.0.0:${dnstapPort |> toString}";
    # See the private mixin for the write portion
  };

  # Firewall
  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" ip saddr {${
      dnsIps |> lib.concatStringsSep ", "
    }} tcp dport ${dnstapPort |> toString} accept
  '';
}
