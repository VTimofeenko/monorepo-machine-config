/**
  Host-side microvm modules.

  Note: `specialArgs.lib` (bound to the microvm's hostname) is injected by
  `mkMicroVMHostModule` in `flake-lib.nix`, not here.
*/
microVMName:
{ lib, ... }:
{
  microvm.vms.${microVMName} = {
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
        id = "mvm-${microVMName}";
        mac = (lib.homelab.getHost microVMName).networks.lan.macAddr;
        macvtap = {
          link = "phy-lan";
          mode = "bridge";
        };
      }
    ];
  };

  fileSystems."/vms/${microVMName}" = {
    device = "/dev/disk/by-label/VMs";
    options = [
      "defaults"
      "noatime"
      "subvol=${microVMName}"
    ];
    depends = [ "/vms" ];
  };
}
