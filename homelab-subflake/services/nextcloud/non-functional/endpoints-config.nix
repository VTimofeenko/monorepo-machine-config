endpoints: { lib, ... }:
{
  services.nginx.virtualHosts.${(lib.homelab.getService "nextcloud").fqdn}.listenAddresses =
    lib.homelab.getOwnIpInNetwork "backbone-inner" |> lib.singleton;
}
