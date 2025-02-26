/**
  Tiny tiny RSS comes with an nginx module. Rather than reimplementing the wheel, I
  will let the nixpkgs module handle the ingress.
*/
{ lib, ... }:
{
  networking.firewall.extraInputRules =
    [
      80
    ]
    |> map (
      it:
      [
        ''ip saddr ${lib.homelab.getHostIpInNetwork "fluorine" "backbone-inner"}'' # TODO: parameterize this as the global SSL proxy
        ''tcp dport ${it |> toString} accept;''
      ]
      |> builtins.concatStringsSep " "
    )
    |> lib.concatLines;
}
