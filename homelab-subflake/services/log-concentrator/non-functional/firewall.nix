{
  vectorPort,
  syslogPort,
  accessLogConcentratorPort,
  ...
}:
{
  config,
  lib,
  ...
}:
{
  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" tcp dport ${vectorPort |> toString} accept
    iifname "phy-lan" ip saddr ${
      config.homelab.services.log-concentrator.rsyslogClients
      |> map (lib.homelab.hosts.getIPInNetwork "lan")
      |> lib.concatStringsSep ", "
      |> (it: "{ ${it} }")
    } udp dport ${syslogPort |> toString} accept
    iifname "backbone-inner" ip saddr ${"ssl-proxy" |> lib.homelab.getServiceInnerIP} tcp dport ${
      accessLogConcentratorPort |> toString
    } accept comment "Allow log shipper to deposit access logs from the ssl proxy"
  '';
}
