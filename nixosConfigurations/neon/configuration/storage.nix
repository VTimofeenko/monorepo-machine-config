{ pkgs, ... }:
let
  disks = {
    one = "8cc1e2d2-1ff9-4145-bbac-74a3056a242f";
  };
in
{
  boot.kernelParams = [ "libata.force=noncq" ];

  fileSystems."/data" = {
    fsType = "btrfs";
    device = "/dev/disk/by-uuid/${disks.one}";
    options = [
      "defaults"
      "noatime"
    ];
  };

  fileSystems."/vms" = {
    fsType = "btrfs";
    device = "/dev/disk/by-label/VMs";
    options = [
      "defaults"
      "noatime"
    ];
  };

  environment.systemPackages = [
    pkgs.btrfs-progs
    pkgs.smartmontools
    pkgs.iotop
  ];

  /**
    This node runs on `PRIME B760M` motherboard. A PWM fan is connected to
    `CHA_FAN1` header and cools down the HDDs.

    `hddfancontrol` will ramp the fan up when they are over 30C and max the
    speed out at 50 degrees.

    `/sys/class/hwmon/` value was found using `pwmconfig` from `lm-sensors`
    package.

    Apparently for `pwmconfig` to see this fan, the bios must have the speed
    set to maximum.

    One thing to note is that the `/sys/class/hwmon/hwmon*` numbering depends
    on the order of the kernel modules. Better point `hddfancontrol` at the
    target of `readlink -f` which will point to the actual device.
  */
  boot.kernelModules = [ "nct6775" ];
  services.hddfancontrol = {
    enable = true;

    settings.harddrives = {
      disks = disks |> builtins.attrValues |> map (x: "/dev/disk/by-uuid/${x}");
      pwmPaths = [
        "/sys/devices/platform/nct6775.656/hwmon/hwmon1/pwm1:255:0"
      ];
      logVerbosity = "DEBUG";
    };
  };

  systemd.services.hddfancontrol-harddrives.serviceConfig.Restart = "on-failure";
}
