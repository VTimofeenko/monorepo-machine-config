{ serviceName, lib, ... }:
let
  grafanaDashboardId = "ddw8m8mjq3tvkf";
  domain = lib.homelab.getServiceFqdn serviceName;
in
{
  Alert = [
    {
      title = "Gitea service down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
    }
  ];
  Error = [
    {
      title = "Disk critically full";
      expr = ''(node_filesystem_avail_bytes{mountpoint="/var/lib/gitea"} * 100) / node_filesystem_size_bytes{mountpoint="/var/lib/gitea"} < 10'';
      description = "Free disk space < 10%";
    }
  ];
  Warning = [
    {
      title = "Disk almost full";
      expr = ''(node_filesystem_avail_bytes{mountpoint="/var/lib/gitea"} * 100) / node_filesystem_size_bytes{mountpoint="/var/lib/gitea"} < 20'';
      description = "Free disk space < 20%";
    }
    {
      title = "Sustained proxy errors";
      expr = ''rate(ssl_proxy_nginx_http_requests_total{domain="${domain}",result!="2xx_3xx_success"}[5m]) > 0'';
    }
  ];
}
|> builtins.mapAttrs (_: v: v |> map (it: it // { inherit grafanaDashboardId; }))
