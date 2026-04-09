{ serviceName, lib, ... }:
{
  Alert = [
    {
      title = "service down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
    }
    {
      title = "disk almost full";
      expr =
        let
          mountpoint = "/var/lib/prometheus2";
          host = serviceName |> lib.homelab.getServiceHost;
        in
        ''(node_filesystem_avail_bytes{mountpoint="${mountpoint}",host="${host}"} * 100) / node_filesystem_size_bytes{mountpoint="${mountpoint}",host="${host}"} < 10'';
      description = "Free disk space < 10%";
    }
  ];
}
