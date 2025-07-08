{ servicePort, syslogPort, ... }:
{
  config,
  lib,
  ...
}:
{
  services.vector.settings = {
    # Has `vector` prefix to denote that it's vector-specific
    sources.vector-log-concentrator = {
      type = "vector";
      address = "0.0.0.0:${servicePort |> toString}"; # Listen on all interfaces, let firewall handle the access
    };
  };

  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" tcp dport ${servicePort |> toString} accept
    iifname "phy-lan" ip saddr ${
      config.homelab.services.log-concentrator.rsyncClients
      |> map (lib.homelab.hosts.getIPInNetwork "lan")
      |> lib.concatStringsSep ", "
      |> (it: "{ ${it} }")
    } udp dport ${syslogPort |> toString} accept
  '';
}
