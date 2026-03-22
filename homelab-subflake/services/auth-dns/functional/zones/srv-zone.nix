/**
  Implements the `srv.*` zone.

  All instances of managed services get two records:

  1. `CNAME` record that points the record to one of:
  - to the HOST where the service is located if this service does not have SSL termination
  - points the record to the host itself if there is no SSL termination

  2. `_i.` `TXT` record that tells which host the instance is located at.
*/
{ lib, ... }:
let
  zone = lib.homelab.getSettings.publicDomainName;
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
in
{
  services.nsd.zones.${zone}.data =
    [
      # Zone header
      (srvLib.mkZoneBase {
        domain = zone;
        nameserverIPs = "lan" |> lib.homelab.getNetwork |> builtins.getAttr "dnsServers";
        inherit lib;
        ttl = 1800; # TODO: maybe higher?
      })

      # CNAME records for SSL proxied services
      (
        (lib.homelab.getManifest "ssl-proxy").srvLib.getProxiedServices
        |> map lib.homelab.services.get
        |> builtins.catAttrs "domain"
        |> (
          it:
          lib.mapCartesianProduct ({ a, b }: srvLib.mkCNAMERecord a b) {
            a = it;
            b = lib.homelab.hosts.getWithService "ssl-proxy" |> map (lib.flip lib.homelab.hosts.getFQDNInNetwork "lan");
          }
        )
      )
    ]
    |> lib.flatten
    |> lib.concatStringsSep "\n";
}
