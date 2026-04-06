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

  # FIXME: missing `file` attribute — verify nextcloud-exporter-token secret is declared
  #        in private modules or add: file = lib.homelab.getSrvSecret "nextcloud" "nextcloud-exporter-token";
  age.secrets."nextcloud-exporter-token".owner = config.services.prometheus.exporters.nextcloud.user;

  services.prometheus.exporters.nextcloud = {
    enable = true;
    inherit port;
    tokenFile = config.age.secrets."nextcloud-exporter-token".path;
    openFirewall = lib.mkForce false;
    url = "nextcloud" |> lib.homelab.getServiceFQDN |> (it: "https://${it}");
  };
}
