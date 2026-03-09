{ port, serviceName, ... }:
{ lib, ... }:
let
  ports = lib.toList port;
in
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "${serviceName}-ssl-probe";
      metrics_path = "/probe";
      params.target = [ "${"gitea" |> lib.homelab.getServiceFqdn}:443" ];
      static_configs = [
        {
          targets = map (port: "${serviceName |> lib.homelab.getServiceInnerIP}:${toString port}") ports;
        }
      ];
    }
  ];
}
