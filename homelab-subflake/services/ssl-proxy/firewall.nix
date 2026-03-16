{ lib, ... }:
let
  allowedTCPPorts = [
    22 # TODO: get this value from nginx streams?
    80
    443
  ];
in
{
  networking.firewall.interfaces = {
    phy-lan = { inherit allowedTCPPorts; };
    backbone = { inherit allowedTCPPorts; };
  };

  networking.firewall.extraReversePathFilterRules = ''
    iifname "backbone" ip saddr { ${
      (lib.homelab.getNetwork "client").settings.clientNodes
      |> builtins.attrValues
      |> builtins.catAttrs "ipAddress"
      |> map (it: "${it}/32")
      |> builtins.concatStringsSep ", "
    } } accept
  '';
}
