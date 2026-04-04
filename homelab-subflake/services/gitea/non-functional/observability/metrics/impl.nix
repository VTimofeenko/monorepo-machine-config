{ ... }:
{
  services.gitea.settings.metrics = {
    # Gotta be "ENABLED" IN ALL CAPS
    ENABLED = true;
    TOKEN = "";
  };
}
