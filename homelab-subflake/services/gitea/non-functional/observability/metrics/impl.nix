{ lib, ... }:
{
  services.gitea.settings.metrics = {
    # Gotta be "ENABLED" IN ALL CAPS
    ENABLED = true;
    TOKEN = (lib.homelab.getServiceConfig "gitea").metricsToken;
  };
}
