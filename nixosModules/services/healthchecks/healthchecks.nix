{
  lib,
  config,
  pkgs,
  ...
}:
let
  srvName = "healthchecks";
  fqdn = getServiceFqdn srvName;

  inherit (lib.homelab)
    getServiceFqdn
    getSrvSecret
    ;
in
{
  # Secret
  age.secrets."${srvName}-secret" = {
    file = getSrvSecret srvName "secret";
    owner = config.services."${srvName}".user;
  };

  # Service itself
  services.healthchecks = {
    enable = true;

    # The package override defines dome django CSRF settings that are needed for my network setup
    package = pkgs.healthchecks.overrideAttrs (
      super:
      let
        inherit (super) secrets;
      in
      rec {
        localSettings = pkgs.writeText "local_settings.py" ''
          import os

          STATIC_ROOT = os.getenv("STATIC_ROOT")

          ${lib.concatLines (
            map (secret: ''
              ${secret}_FILE = os.getenv("${secret}_FILE")
              if ${secret}_FILE:
                  with open(${secret}_FILE, "r") as file:
                      ${secret} = file.readline()
            '') secrets
          )}
          # CSRF stuff
          SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
          CSRF_ALLOWED_ORIGINS = ["https://${fqdn}"]
          CORS_ORIGINS_WHITELIST = ["https://${fqdn}"]
          REMOTE_USER_HEADER = "HTTP_X_EMAIL"
          AUTHENTICATION_BACKENDS = ["hc.accounts.backends.CustomHeaderBackend"]
        '';

        # Override this to make sure that proper localSettings is passed
        installPhase = ''
          mkdir -p $out/opt/healthchecks
          cp -r . $out/opt/healthchecks
          chmod +x $out/opt/healthchecks/manage.py
          cp ${localSettings} $out/opt/healthchecks/hc/local_settings.py
        '';
      }
    );
    settings = {
      SECRET_KEY_FILE = config.age.secrets."${srvName}-secret".path;
      ALLOWED_HOSTS = [ fqdn ];
      INTEGRATIONS_ALLOW_PRIVATE_IPS = "True"; # Allow running checks on classful IPs in LAN
      REGISTRATION_OPEN = false;
      SITE_ROOT = "https://${fqdn}";

      DEBUG = false;

      # Disabled integrations
      MATTERMOST_ENABLED = "False";
      MSTEAMS_ENABLED = "False";
      OPSGENIE_ENABLED = "False";
      PAGERTREE_ENABLED = "False";
      PD_ENABLED = "False";
      SLACK_ENABLED = "False";
      SPIKE_ENABLED = "False";
      VICTOROPS_ENABLED = "False";
      ZULIP_ENABLED = "False";
    };
  };

  imports = [
    ./fix-401010-pydantic-error.nix

  ];
}
