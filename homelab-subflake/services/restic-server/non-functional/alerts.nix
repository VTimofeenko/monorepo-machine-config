{ serviceName, lib, ... }:
let
  host = lib.homelab.getServiceHost serviceName;
  fsDiskLabel = ''mountpoint="/var/lib/restic", host="${host}"'';
in
{
  Alert = [
    {
      title = "Restic service down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
    }
  ];
  Warning = [
    {
      title = "Disk almost full";
      expr = "(node_filesystem_avail_bytes{${fsDiskLabel}} / node_filesystem_size_bytes{${fsDiskLabel}}) * 100 < 10";
      grafanaDashboardId = "ec51fd06-a034-4271-90e3-62d95310044a";
    }
    {
      title = "No backup snapshots in 30h";
      expr = ''sum(increase(rest_server_blob_write_total{resource="srv:${serviceName}", type="snapshots"}[30h])) == 0'';
      grafanaDashboardId = "ec51fd06-a034-4271-90e3-62d95310044a";
    }
  ];
}
