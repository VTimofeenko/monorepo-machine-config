{
  lib,
  config,
  ...
}:
let
  port = (lib.homelab.getManifest "nextcloud").endpoints.metrics.port;
in
{
  services.nextcloud.settings.loglevel = 1;
  services.nextcloud.settings.log_type_audit = "syslog";

  services.prometheus.exporters.nextcloud = {
    enable = true;
    inherit port;
    tokenFile = config.age.secrets.nextcloud-exporter-token.path;
    openFirewall = lib.mkForce false;
    url = "nextcloud" |> lib.homelab.getServiceFQDN |> (it: "https://${it}");
  };
}
