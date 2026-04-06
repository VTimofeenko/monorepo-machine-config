endpoints: { lib, ... }:
{
  services.nginx.virtualHosts.${(lib.homelab.getService "filedump").fqdn}.listenAddresses =
    lib.homelab.getOwnIpInNetwork "backbone-inner" |> lib.singleton;
}
