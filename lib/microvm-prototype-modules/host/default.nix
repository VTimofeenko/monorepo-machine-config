/**
  Host-side microvm modules
*/
microVMName:
{
  pkgs,
  lib,
  data-flake,
  ...
}:
let
  inherit (data-flake.lib) homelab;

  homelabExt =
    _: _:
    {
      inherit homelab;
    }
    |> (lib.flip builtins.removeAttrs [ "_mkOwnFuncs" ]) # Remove generating function
    |> (lib.recursiveUpdate { homelab = homelab._mkOwnFuncs microVMName; }); # Bind get functions to hostname, producing `getOwn*` functions
in
{
  microvm.vms.${microVMName} = {
    # Done to add custom lib functions
    specialArgs.lib = pkgs.lib.extend (lib.composeManyExtensions [ homelabExt ]); # TODO: may need a more generic function here to pass `localLib` like what the flake does

    # It is highly recommended to share the host's nix-store
    # with the VMs to prevent building huge images.
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
