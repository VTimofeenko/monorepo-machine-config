/**
  Sets up the DNS view that the VPN clients get.

  Implementation note:
  Originally I had the idea of doing something like
  `$SRV_NAME` > `CNAME` `$HOST_NAME`
  $HOST_NAME gets resolved to 192.168 for LAN, $CLIENT_IP for client
  Unfortunately it does not work, see https://github.com/NLnetLabs/unbound/issues/747
*/
{ lib, config, ... }:
let
  inherit (import ../lib.nix) mkARecord;
  clientNetViewName = "wg_client_network";
  client = lib.homelab.getNetwork "client";
  inherit (config) my-data;
in
{
  services.unbound.settings.server.access-control-view = [
    "${client.settings.clientSubNet}.1/24 ${clientNetViewName}"
  ];
  services.unbound.settings.view = [
    {
      name = clientNetViewName;
      local-zone = [ ''"${lib.homelab.getSettings.publicDomainName}." static'' ];
      local-data =
        # Add nix-computed services on the backbone
        my-data.services.all
        |> lib.filterAttrs (_: lib.hasAttr "networkAccess") # Get only attributes with networkAccess
        |> lib.filterAttrs (_: v: v.networkAccess == [ "backbone" ]) # Find services marked as "available only over backbone"
        |> builtins.attrValues
        |> builtins.catAttrs "fqdn" # Extract FQDN
        |> map (it: ''"${mkARecord it (lib.homelab.getHostIpInNetwork "fluorine" "backbone")}"'') # TODO: parameterize
      ;
      view-first = "yes";
    }
  ];
}
