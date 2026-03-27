{
  lib,
  ...
}:
{
  services.ntpd-rs = {
    metrics.enable = true;
    # Port 9975 must match endpoints.metrics.port in manifest.nix
    settings.observability.metrics-exporter-listen = "${
      "ntp" |> lib.homelab.getServiceInnerIP
    }:9975";
  };

  # Firewall rules auto-generated from endpoints.metrics definition
}
