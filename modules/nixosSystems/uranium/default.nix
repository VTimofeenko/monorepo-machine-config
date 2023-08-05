# [[file:../../../new_project.org::*Uranium specific system][Uranium specific system:1]]
{ pkgs
, lib
, config
, my-sway-config
, my-doom-config
, ...
}@inputs:
let
  cfg = config.myMachines.uranium;
in
{
  imports = [
    ../../de
    inputs.wg-namespace-flake.nixosModules.default
    # TODO: add optional phone network here commented
    ../../network/ethernet.nix
    ../../network/public-firewall.nix
    ./hardware # (ref:uranium-hw-import)
  ];
  # options.myMachines.uranium = {
  #   network = lib.mkOption {
  #     description = "Which network to use";
  #     type = lib.types.enum [ "wifi-lan" "eth" ];
  #     default = "wifi-lan";
  #   };
  # };
  # config = { myMachines.uranium.network = "eth"; }
  #          //
  #          ( lib.mkIf (cfg.network != "wifi-lan") (import ../../network/public-firewall.nix  lib) )
  #          //
  #          ( lib.mkIf (cfg.network == "eth") (import ../../network/ethernet.nix) )
  #          //
  #          ( lib.mkIf (cfg.network == "wifi-lan") (import ../../network/lan-wifi.nix { inherit config lib; inherit (inputs) infra; }) )
  # ;
  # config.myMachines.uranium.network = "eth";
}
# Uranium specific system:1 ends here
