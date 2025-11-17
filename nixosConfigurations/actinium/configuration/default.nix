{ lib, modulesPath, ... }:
let
  hostConfig = lib.homelab.getOwnHostConfig;
in
{
  # Boot
  boot = {
    loader.grub.device = "/dev/sda";
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "xen_blkfront"
        "vmw_pvscsi"
      ];
      kernelModules = [ "nvme" ];
    };
  };

  # File systems
  fileSystems = {
    "/" = {
      device = "/dev/sda1";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  # Network
  systemd.network = {
    links."10-wan" = {
      enable = true;
      linkConfig.Name = "wan";
      matchConfig.PermanentMACAddress = hostConfig.macAddr;
    };

    networks."10-wan" = {
      enable = true;
      name = "10-wan";
      matchConfig.Name = lib.mkForce "wan";
      address = "${hostConfig.ipAddress}/${hostConfig.netmask}" |> lib.toList;
      gateway = hostConfig.gateway |> lib.toList;
      networkConfig = {
        DHCP = "no";
        # This will also disable IPv6 assigning
        LinkLocalAddressing = "no";
      };
      DHCP = "no";
    };
  };

  # Misc
  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # Imports
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./tailscale.nix
  ];
}
