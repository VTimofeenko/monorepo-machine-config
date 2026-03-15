_:
{ lib, ... }:
{
  services.nginx.virtualHosts.${(lib.homelab.getService "cyberchef").fqdn}.listenAddresses =
    lib.homelab.getOwnIpInNetwork "backbone-inner" |> lib.singleton;
}
