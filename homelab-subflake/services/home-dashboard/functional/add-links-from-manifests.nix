{
  lib,
  ...
}:
{
  services.homepage-dashboard.services =
    # Take data-flake and self `serviceModules`
    lib.homelab.getManifests
    # Filter only ones that have "dashboard" attribute
    |> lib.filterAttrs (
      _: value: (value |> builtins.hasAttr "dashboard") && (!builtins.isNull value.dashboard)
    )
    # The general format at this point is:
    # `service-foo = { category = "bar"; links = [ { { path = "/"; description = "baz"; icon = "foz"; name = "qux"; }}] }`
    |> lib.mapAttrs (
      name: value:
      let
        inherit (value) dashboard;
      in
      {
        "${dashboard.category}" =
          dashboard.links
          |> map (it: {
            "${it.name}" = {

              # Human readable description of the service on the dashboard
              inherit (it) description;

              # This will be the URL that opens when clicking on the tile
              # Explicit `absoluteURL` wins
              # If problems here – check `../../../lib/manifest-options.nix`
              href =
                if !builtins.isNull it.absoluteURL then
                  it.absoluteURL
                else
                  let
                    service = if builtins.isNull it.service then name else it.service;
                  in
                  service
                  |> lib.homelab.getServiceFqdn
                  |> (it': "https://${it'}")
                  |> (it': "${it'}${it.path |> toString}");

              # Get the icon, but fallback to `selfhosted` icon
              icon =
                "filedump"
                |> lib.homelab.getServiceFqdn
                |> (it': "https://${it'}")
                |> (it': "${it'}/dashboard-icons/png")
                |> (it': "/${it'}/${if builtins.isNull it.icon then "selfhosted" else it.icon}.png");
            };
          });
      }
    )
    |> builtins.attrValues
    # Merge. This is mostly done so that categories don't override each other.
    # I believe usually first wins by default.
    |> lib.localLib.recursiveMerge
    # Looks like homepage expects a list of single attribute sets per category.
    # Rearrange the list as it wants.
    |> lib.attrsToList
    |> map (it: {
      "${it.name}" = it.value;
    });
}
