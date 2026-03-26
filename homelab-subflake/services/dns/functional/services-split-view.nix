/**
  Configures view for services that may be in LAN by default, but they should
  be resolved to `backbone-inner` for all managed hosts, forcing them to go
  over `backbone-inner` network.
*/
{ lib, ... }:
let
  inherit (lib.homelab.getManifest "auth-dns") srvLib;
  clientNetViewName = "mixed-managed-infra-services-vw";

  # Get all managed hosts (those in backbone-inner network)
  managedHosts =
    lib.homelab.hosts.getAll
    |> lib.filterAttrs (hostName: _: lib.homelab.isInNetwork hostName "backbone-inner")
    |> lib.attrNames;

  # Services that need split view (available in LAN for unmanaged, backbone-inner for managed)
  # If this list grows, might need some setting in data
  splitViewServices = [
    "mqtt"
    "log-concentrator"
  ];
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
      local-data =
        # A records for split-view services pointing directly to their host's backbone-inner IP
        splitViewServices
        |> map lib.homelab.getService
        |> map (
          svc:
          srvLib.mkARecord svc.fqdn (lib.homelab.hosts.getInnerIP svc.onHost)
        )
        |> lib.flatten
        |> map (it: "\"${it}\""); # Escape the data, necessary
      view-first = "yes";
    }
  ];
}
