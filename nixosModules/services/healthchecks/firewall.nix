{ lib, ... }:
let
  srvName = "healthchecks";
  inherit (lib.homelab) getServiceConfig;
in
{
  networking.firewall.extraInputRules =
    [
      ''ip saddr ${lib.homelab.getHostIpInNetwork "fluorine" "backbone-inner"}'' # TODO: parameterize this as the global SSL proxy
      ''tcp dport ${(getServiceConfig srvName).proxyPort |> toString} accept''
    ]
    |> builtins.concatStringsSep " ";

}
