{
  # Services in LAN by default, answered with their `backbone-inner` address
  # to hosts in the mesh (`./functional/services-split-view.nix`) and to
  # roaming nodes (`./functional/client-view.nix`).
  # If this list grows, might need some setting in data
  splitViewServices = [
    "mqtt"
    "log-concentrator"
  ];
}
