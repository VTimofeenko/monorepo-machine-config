/**
  Ensures that a partition is mounted for `srv:fava`.

  The partition is mounted at fava's StateDirectory (/var/lib/fava) so both
  the fava process and fava-helper (which writes the beancount checkout there)
  share the same persistent volume.
*/
{ ... }:
{
  systemd = {
    services.fava.unitConfig.RequiresMountsFor = [ "/var/lib/fava" ];
    services.fava-helper.unitConfig.RequiresMountsFor = [ "/var/lib/fava" ];
    mounts = [
      {
        what = "/dev/disk/by-label/fava";
        where = "/var/lib/fava";
        options = "noatime";
      }
    ];
  };
}
