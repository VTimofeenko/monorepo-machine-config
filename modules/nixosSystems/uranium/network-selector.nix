# [[file:../../../new_project.org::*Network selector][Network selector:1]]
{ config, lib, ... }@inputs:
let
  cfg = config.myMachines.uranium.network;
in
lib.mkMerge [
  (lib.mkIf (cfg != "wifi-lan") (import ../../network/public-firewall.nix { inherit lib; }))
  (lib.mkIf (cfg == "eth") (import ../../network/ethernet.nix))
  (lib.mkIf (cfg == "wifi-lan") (
    import ../../network/lan-wifi.nix {
      inherit config lib;
      inherit (inputs) infra;
    }
  ))
]
# Network selector:1 ends here
