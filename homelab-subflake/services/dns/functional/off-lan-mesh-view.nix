/**
  View for hosts in the mesh that are not in LAN (e.g. a VPS), and roaming
  nodes, which never use LAN directly (`ipsoot-wayhut`): the default answers
  are LAN addresses.

  Everything reachable over `backbone-inner` is answered with that address:
  SSL proxied services, split view services and services listening on
  `backbone-inner`. The rest falls through to the default answers.
*/
{ lib, ... }:
let
  inherit ((lib.homelab.getManifest "dns").srvLib) splitViewServices mkInnerRecords;
  viewName = "off-lan-mesh-vw";

  hosts =
    (lib.homelab.getNetwork "backbone-inner").hostsInNetwork
    |> lib.attrNames
    |> builtins.filter (
      hostName: !lib.homelab.isInNetwork hostName "lan" || lib.homelab.isRoaming hostName
    );

  services =
    (lib.homelab.getManifest "ssl-proxy").srvLib.getProxiedServices
    ++ splitViewServices
    ++ (
      lib.homelab.services.getAll
      |> lib.filterAttrs (
        _: v:
        v ? fqdn && !builtins.elem "alien" v.groups && builtins.elem "backbone-inner" (v.networkAccess or [ ])
      )
      |> lib.attrNames
    );
in
{
  services.unbound.settings.server.access-control-view =
    hosts
    |> lib.concatMap (
      hostName:
      # `backbone` while a host resolves over it
      [
        "backbone"
        "backbone-inner"
      ]
      |> builtins.filter (lib.homelab.isInNetwork hostName)
      |> map (net: "${lib.homelab.getHostIpInNetwork hostName net}/32 ${viewName}")
    );

  services.unbound.settings.view = [
    {
      name = viewName;
      local-zone = [ ''"${lib.homelab.getSettings.publicDomainName}." transparent'' ];
      local-data = mkInnerRecords services;
      view-first = "yes";
    }
  ];
}
