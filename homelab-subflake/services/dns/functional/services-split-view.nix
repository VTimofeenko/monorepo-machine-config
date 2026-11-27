/**
  Configures view for services that may be in LAN by default, but they should
  be resolved to `backbone-inner` for all managed hosts, forcing them to go
  over `backbone-inner` network.
*/
{ lib, ... }:
let
  inherit ((lib.homelab.getManifest "dns").srvLib) splitViewServices mkInnerRecords;
  clientNetViewName = "mixed-managed-infra-services-vw";

  # Get all managed hosts (those in backbone-inner network) in LAN.
  # Its fallback here would be LAN answers: roaming and off-LAN ones get
  # their own view (`./off-lan-mesh-view.nix`)
  managedHosts =
    lib.homelab.hosts.getAll
    |> lib.filterAttrs (
      hostName: _:
      lib.homelab.isInNetwork hostName "backbone-inner"
      && lib.homelab.isInNetwork hostName "lan"
      && !lib.homelab.isRoaming hostName
    )
    |> lib.attrNames;

in
{
  services.unbound.settings.server.access-control-view =
    # Map all managed hosts' backbone-inner IPs to this view
    # TODO: must also include LAN IPs. Implement in nitrogen migration
    managedHosts |> map (host: "${lib.homelab.hosts.getInnerIP host}/32 ${clientNetViewName}");

  services.unbound.settings.view = [
    {
      name = clientNetViewName;
      # Use transparent to allow fallback to stub-zone for records not defined here
      local-zone = [ ''"${lib.homelab.getSettings.publicDomainName}." transparent'' ];
      # A records for split-view services pointing directly to their host's backbone-inner IP
      local-data = mkInnerRecords splitViewServices;
      view-first = "yes";
    }
  ];
}
