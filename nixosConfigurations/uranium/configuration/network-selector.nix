# [[file:../../../new_project.org::*Network selector][Network selector:1]]
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myMachines.uranium.network;
  basePath = ../../../modules/network;
in
lib.mkMerge [
  (lib.mkIf (cfg != "wifi-lan") (import (basePath + /public-firewall.nix) { inherit lib; }))
  (lib.mkIf (cfg == "eth") (import (basePath + /ethernet.nix)))
  (lib.mkIf (cfg == "adhoc-wifi") (import (basePath + /adhoc-wifi.nix) { inherit config lib; }))
  (lib.mkIf (cfg == "wifi-lan") (import (basePath + /lan-wifi.nix) { inherit config lib; }))
  { environment.systemPackages = [ pkgs.wpa_supplicant_gui ]; }
]
# Network selector:1 ends here
