let
  settings.mainDevice = "/dev/nvme0n1";
in
{
  disko.devices.disk.main = {
    device = settings.mainDevice;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "500M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "64G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [
              "defaults"
              "noatime"
            ];
          };
        };
        plainSwap = {
          size = "8G";
          content.type = "swap";
        };
      };
    };
  };

}
