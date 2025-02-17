{
  data-flake,
  self,
  lib,
  ...
}:
{
  services.homepage-dashboard.services =
    # Take data-flake and self `serviceModules`
    (self.serviceModules // data-flake.serviceModules)
    # Filter only ones that have "dashboard" attribute
    |> lib.filterAttrs (_: value: value |> builtins.hasAttr "dashboard")
    # The general format at this point is:
    # `service-foo = { category = "bar"; links = [ { { path = "/"; description = "baz"; icon = "foz"; name = "qux"; }}] }`
    |> lib.mapAttrs (
      name: value:
      let
        # Some dashboard attrsets are functions
        # TODO: Maybe refactor manifests as functions in general?
        dashboard = if lib.isFunction value.dashboard then value.dashboard { inherit lib; } else value.dashboard;
      in
      {
        "${dashboard.category}" =
          dashboard.links
          |> map (it: {
            "${it.name}" = {
              description = "${it.description or ""}";
              href = it.absoluteURL or "https://${lib.homelab.getServiceFqdn name}${it.path or "/"}";
              # Get the icon, but fallback to `selfhosted` icon
              icon = "https://${lib.homelab.getServiceFqdn "filedump"}/dashboard-icons/png/${
                if it |> builtins.hasAttr "icon" then "${it.icon}.png" else "selfhosted.png"
              }";
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
