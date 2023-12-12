# [[file:../../../new_project.org::*Network selector][Network selector:1]]
{ config, lib, ... }:
let
  cfg = config.myMachines.uranium.network;
in
lib.mkMerge [
  (lib.mkIf (cfg != "wifi-lan") (import ../../network/public-firewall.nix { inherit lib; }))
  (lib.mkIf (cfg == "eth") (import ../../network/ethernet.nix))
  (lib.mkIf (cfg == "adhoc-wifi") (import ../../network/adhoc-wifi.nix { inherit config lib; }))
  (lib.mkIf (cfg == "wifi-lan") (
    import ../../network/lan-wifi.nix {
      inherit config lib;
    }
  ))
]
# Network selector:1 ends here
