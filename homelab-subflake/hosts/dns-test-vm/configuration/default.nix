/**
  Minimal VM configuration for DNS testing.

  This is a simple QEMU VM that only runs dns and auth-dns services.
*/
{ lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" ];

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  # Minimal networking for VM
  networking = {
    useDHCP = lib.mkForce false;
    useNetworkd = lib.mkForce false;
    interfaces.ens3 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "192.168.1.199";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens3";
    };
  };

  # Enable SSH for VM access
  services.openssh.enable = true;
  users.users.root.password = "test";

  system.stateVersion = "24.05";
}
