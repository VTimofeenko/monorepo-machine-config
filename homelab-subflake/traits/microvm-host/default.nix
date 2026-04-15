/**
  MicroVM host infrastructure.

  Applied automatically to any host with at least one microvm (`microvms != []`).
  Sets up macvtap network interfaces and persistence filesystem mounts for each
  hosted microvm, driven entirely by `lib.homelab.getOwnMicrovms`.
*/
{ lib, inputs, ... }:
let
  microvms = lib.homelab.getOwnMicrovms;
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  microvm.vms = lib.genAttrs microvms (microvmName: {
    config.microvm.shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];

    config.microvm.interfaces = [
      {
        type = "macvtap";
        id = "mvm-${microvmName}";
        mac = (lib.homelab.getHost microvmName).networks.lan.macAddr;
        macvtap = {
          link = "phy-lan";
          mode = "bridge";
        };
      }
    ];
  });

  fileSystems = lib.listToAttrs (
    microvms
    |> map (
      microvmName:
      lib.nameValuePair "/vms/${microvmName}" {
        device = "/dev/disk/by-label/VMs";
        options = [
          "defaults"
          "noatime"
          "subvol=${microvmName}"
        ];
        depends = [ "/vms" ];
      }
    )
  );
}
