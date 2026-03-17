# Simple layout
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                label = "nixos";
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
