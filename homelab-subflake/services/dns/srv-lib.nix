{ lib, ... }:
{
  # Services in LAN by default, answered with their `backbone-inner` address
  # to hosts in the mesh (`./functional/services-split-view.nix`,
  # `./functional/off-lan-mesh-view.nix`).
  # If this list grows, might need some setting in data
  splitViewServices = [
    "mqtt"
    "log-concentrator"
  ];

  /**
    `local-data` A records pointing services at their `backbone-inner`
    address: the SSL proxies for centrally terminated services, the service
    itself otherwise.
  */
  mkInnerRecords =
    serviceNames:
    let
      # `getManifest` is not available in manifest's `lib`
      inherit (import ../auth-dns/srv-lib.nix { inherit lib; }) mkARecord;
      sslProxyIPs = lib.homelab.hosts.getWithService "ssl-proxy" |> map lib.homelab.hosts.getInnerIP;
    in
    serviceNames
    |> lib.unique
    |> map lib.homelab.getService
    |> map (
      it:
      (if it.centralSSL then sslProxyIPs else [ (lib.homelab.services.getInnerIP it.serviceName) ])
      |> map (mkARecord it.fqdn)
    )
    |> lib.flatten
    |> map (it: "\"${it}\""); # Escape the data, necessary
}
