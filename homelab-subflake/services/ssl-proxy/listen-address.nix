/**
  Sets up an option to easily propagate and change the `listenAddress` for
  the virtual hosts
*/
{ lib, ... }:
{
  options.services.homelab.ssl-proxy.listenAddresses = lib.options.mkOption {
    default =
      [
        "lan"
        "backbone"
      ]
      |> map lib.homelab.getOwnIpInNetwork;
  };
}
