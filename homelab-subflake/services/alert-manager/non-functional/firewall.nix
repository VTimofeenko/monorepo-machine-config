{ lib, ... }:
{
  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" ip saddr ${lib.homelab.getServiceInnerIP "log-concentrator"} tcp dport ${
      (lib.homelab.getManifest "alert-manager").endpoints.web.port |> toString
    } accept comment "Log concentrator polls the alerts"
  '';
}
