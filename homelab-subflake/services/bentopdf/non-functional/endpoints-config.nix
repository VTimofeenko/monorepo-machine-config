endpoints: { config, lib, ... }:
{
  services.nginx.virtualHosts.${config.services.bentopdf.domain}.listenAddresses =
    lib.homelab.getOwnIpInNetwork "backbone-inner" |> lib.singleton;
}
