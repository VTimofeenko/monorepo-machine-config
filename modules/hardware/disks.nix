{ pkgs, ... }:

{

  services.fstrim.enable = true;

  systemd.tmpfiles.rules =
    [
      "d /scratch 1777 spacecadet users 10d"
    ];

}
