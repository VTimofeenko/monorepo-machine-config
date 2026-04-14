{
  config,
  lib,
  ...
}:
let
  inherit (lib.homelab.getManifest "log-concentrator") endpoints;
in
{
  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" tcp dport ${endpoints.vector.port |> toString} accept
    iifname "phy-lan" ip saddr ${
      config.homelab.services.log-concentrator.rsyslogClients
      |> map (lib.homelab.hosts.getLANIP)
      |> lib.concatStringsSep ", "
      |> (it: "{ ${it} }")
    } udp dport ${endpoints.syslog.port |> toString} accept
    iifname "backbone-inner" ip saddr ${"ssl-proxy" |> lib.homelab.getServiceInnerIP} tcp dport ${
      endpoints.access-logs.port |> toString
    } accept comment "Allow log shipper to deposit access logs from the ssl proxy"
  '';
}
