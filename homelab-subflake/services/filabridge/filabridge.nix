/**
  Toolhead -> spool mapping is still done in web UI.
*/
{ config, ... }:
let
  spoolman = config.services.spoolman;
in
{
  services.filabridge = {
    enable = true;

    settings = {
      # Same host: talk to `srv:spoolman` directly instead of through the proxy and
      # its human-only allowlist
      # TODO: ACL
      spoolman_url = "http://${spoolman.listen}:${toString spoolman.port}";
    };

    # Same PrusaLink auth material as `srv:prusa-exporter`
    # TODO: decouple later
    printers.prusa-core-one = {
      name = "Prusa Core One";
      address = "prusa-printer.home.arpa";
      apiKeyFile = config.age.secrets.prusa-printer-password.path;
    };
  };

  assertions = [
    {
      assertion = spoolman.enable;
      message = "filabridge expects spoolman on the same host";
    }
  ];
}
