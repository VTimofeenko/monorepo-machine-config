{
  port,
  ...
}:
{
  self,
  lib,
  config,
  ...
}:
{
  services.nextcloud.settings.loglevel = 1;
  services.nextcloud.settings.log_type_audit = "syslog";

  age.secrets."nextcloud-exporter-token".owner = config.services.prometheus.exporters.nextcloud.user;

  services.prometheus.exporters.nextcloud = {
    enable = true;
    inherit port;
    tokenFile = config.age.secrets."nextcloud-exporter-token".path;
    openFirewall = lib.mkForce false;
    url = "nextcloud" |> lib.homelab.getServiceFQDN |> (it: "https://${it}");
  };

  imports = [
    (self.serviceModules.prometheus.srvLib.mkBackboneInnerFirewallRules {
      inherit lib port;
    })
  ];
}
