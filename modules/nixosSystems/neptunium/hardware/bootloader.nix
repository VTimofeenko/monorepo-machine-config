# [[file:../../../../new_project.org::*Neptunium bootloader][Neptunium bootloader:1]]
_: {
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
      luks.devices."crypt-root".device = "/dev/disk/by-uuid/687e04e3-c128-4736-8199-2a7a563b4a97";
    };
    kernelModules = [ "kvm-amd" ];
    tmp = {
      useTmpfs = true;
      tmpfsSize = "8G";
    };
  };
}
# Neptunium bootloader:1 ends here
