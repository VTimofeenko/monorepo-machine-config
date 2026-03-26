/**
  Sets up the DNS view that the VPN clients get.

  The general idea:
  1. Client device connects to client WG network
  2. Client device requests a service, let's go with `"gitea"`
  3. DNS is listening on backbone-inner, responds with `backbone-inner` IP of the SSL proxy (this is this view) # TODO: assert listen address here
  4. Client connects to SSL proxy
  5. SSL proxy connects to Gitea over backbone-inner, serves response to client

  Same flow, but client is in LAN (standard zone behavior):

  3. DNS is listening on LAN, responds with `lan` address of the SSL proxy

  Implementation note:
  Originally I had the idea of doing something like
  `$SRV_NAME` > `CNAME` `$HOST_NAME`
  $HOST_NAME gets resolved to 192.168 for LAN, $CLIENT_IP for client
  Unfortunately it does not work, see https://github.com/NLnetLabs/unbound/issues/747
*/
{ lib, ... }:
let
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
  clientNetViewName = "client-vpn-vw";
  client = lib.homelab.getNetwork "client";
in
{
  services.unbound.settings.server.access-control-view = [
    "${client.settings.clientSubNet}.1/24 ${clientNetViewName}"
  ];

  services.unbound.settings.view = [
    {
      name = clientNetViewName;
      local-zone = [ ''"${lib.homelab.getSettings.publicDomainName}." static'' ];
      local-data =
        # New logic:
        # Grab all SSL proxied services + services that opt into being available over client network
        (lib.homelab.getManifest "ssl-proxy").srvLib.getProxiedServices
        ++ (
          lib.homelab.services.getAll
          |> lib.filterAttrs (
            _: v:
            v ? "networkAccess" && builtins.elem "client" v.networkAccess && !builtins.elem "nonWeb" v.groups
          )
          |> lib.attrNames
        )
        |> lib.unique
        |> map lib.homelab.getService
        |> map (it: {
          inherit (it) fqdn;
          # If central SSL – point at `ssl-proxy`, otherwise point at the service itself
          targets =
            if it.centralSSL then
              lib.homelab.hosts.getWithService "ssl-proxy" |> map lib.homelab.hosts.getInnerIP
            else
              it.serviceName |> lib.homelab.services.getInnerIP |> lib.singleton;
        })
        |> map (
          it:
          lib.mapCartesianProduct ({ fqdn, target }: srvLib.mkARecord fqdn target) {
            fqdn = it.fqdn |> lib.singleton;
            target = it.targets;
          }
        )
        |> lib.flatten
        |> map (it: "\"${it}\""); # Escape the data, necessary
      view-first = "yes"; # Forces view to be served first. Necessary, the view data is the source of truth. Upstream should not be engaged.
    }
  ];
}
