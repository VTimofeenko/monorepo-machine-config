{ serviceName, lib, ... }:
{
  Emergency = [
    {
      title = "service down";
      expr = ''absent(nextcloud_up{resource="srv:${serviceName}"}) or nextcloud_up{resource="srv:${serviceName}"} == 0'';
    }
    {
      title = "disk almost full";
      expr =
        let
          host = serviceName |> lib.homelab.getServiceHost;
        in
        ''(node_filesystem_avail_bytes{mountpoint=~"/var/lib/nextcloud.*",host="${host}"} * 100) / node_filesystem_size_bytes{mountpoint=~"/var/lib/nextcloud.*",host="${host}"} < 10'';
      description = "Free disk space < 10%";
    }
  ];
}
