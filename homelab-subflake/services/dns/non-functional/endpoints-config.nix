_: { lib, ... }:
let
  inherit (lib.homelab)
    getOwnIpInNetwork
    getOwnHost
    getService
    ;
  dnsServiceName =
    getOwnHost
    |> builtins.getAttr "servicesAt"
    |> builtins.filter (name: (getService name).moduleName == "dns")
    |> builtins.head;

  thisSrv = getService dnsServiceName;

in
{
  services.unbound.settings.server.interface = thisSrv.networkAccess |> map getOwnIpInNetwork;
}
