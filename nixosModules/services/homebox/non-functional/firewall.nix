{ lib, ... }:
let
  port = 7745;
in
{
  # Make sure the appropriate port is set in the service
  services.homebox.settings.HBOX_WEB_PORT = port |> toString;

  networking.firewall.extraInputRules =
    [
      ''ip saddr ${lib.homelab.getHostIpInNetwork "fluorine" "backbone-inner"}'' # TODO: parameterize this as the global SSL proxy
      ''tcp dport ${port |> toString} accept''
    ]
    |> builtins.concatStringsSep " ";
}
