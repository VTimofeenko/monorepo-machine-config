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
      })

      # CNAME records for SSL proxied services
      (
        (lib.homelab.getManifest "ssl-proxy").srvLib.getProxiedServices
        |> map lib.homelab.services.get
        |> builtins.catAttrs "domain"
        # Future proof: do this for all SSL proxies
        |> (
          it:
          lib.mapCartesianProduct ({ a, b }: srvLib.mkCNAMERecord a b) {
            a = it;
            b =
              lib.homelab.hosts.getWithService "ssl-proxy"
              |> map (lib.flip lib.homelab.hosts.getFQDNInNetwork "lan"); # TODO: revisit "`lan`" here. I don't remember how exactly unbound views work with this
          }
        )
      )

      # CNAME records for non-SSL proxied services
      (
        lib.homelab.services.getAll
        |> lib.filterAttrs (n: v: !builtins.elem "alien" v.groups || n == "nfs") # Exclude alien services, except NFS. # TODO: Maybe come up with a better separation of truly remote services vs NFS on NAS that I just don't declaratively manage
        |> lib.filterAttrs (_: v: !builtins.elem "nonWeb" v.groups) # exclude non-web services (DNS, DHCP, etc.)
        |> lib.filterAttrs (_: v: !v.centralSSL) # exclude non-web services (DNS, DHCP, etc.)
        |> lib.mapAttrsToList (
          _: v:
          let
            # - Certain services (NTP/MQTT, etc.) need to be in LAN so they can
            #   serve non-VPN clients. They have `"lan"` in `networkAccess`.
            # - Other services (database) don't need to be in LAN, they are
            #   accessible only over VPN.
            # - If a service is present in both and handles its own termination
            #   (`keycloak`) – LAN wins for non-VPN clients, but unbound (`dns`)
            #   should handle the split view
            targetNet = if builtins.elem "lan" v.networkAccess then "lan" else "backbone-inner";
          in
          srvLib.mkCNAMERecord v.domain (v.onHost |> lib.flip lib.homelab.hosts.getFQDNInNetwork targetNet)
        )
      )

      # `_i.<service>` record that tells me where a service is
      (
        lib.homelab.services.getAll
        |> lib.filterAttrs (n: v: !builtins.elem "alien" v.groups || n == "nfs") # See above
        # Create a `TXT` record for _all_ services. If a service does not have a domain, fall back to service name
        |> lib.mapAttrsToList (n: v: srvLib.mkRecord "TXT" "_i.${v.domain or n}" ''"real-host=${v.onHost}"'')
        )
    ]
    |> lib.flatten
    |> lib.concatStringsSep "\n";
}
