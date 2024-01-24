{ nixpkgs-unstable, config, pkgs, ... }:
let
  inherit (config) my-data;
  srvConfig = my-data.lib.getServiceConfig "home-assistant";
  homeassistantUser = config.systemd.services.home-assistant.serviceConfig.User;

  /* This approach makes openssl permitted only in this module */
  pkgs-unstable = import nixpkgs-unstable {
    inherit (pkgs) system;
    config.permittedInsecurePackages = [
      # Needed by home assistant
      "openssl-1.1.1w"
    ];
  };
in
{
  /* Secrets */
  age.secrets.ha-secret = {
    file = my-data.lib.getSrvSecret "home-assistant" "ha-secrets";
    owner = homeassistantUser;
    path = "${config.services.home-assistant.configDir}/secrets.yaml";
  };

  services.home-assistant = {
    /* Using the latest version from unstable */
    package = (pkgs-unstable.home-assistant.overrideAttrs (_: {
      doInstallCheck = false;
    })).override {
      packageOverrides = _: super: {
        python-telegram-bot = super.python-telegram-bot.overridePythonAttrs (oldAttrs: {
          version = "13.1";
          src = pkgs.fetchPypi {
            inherit (oldAttrs) pname;
            version = "13.1";
            hash = "sha256-X+67CO0I17cc60wFNyufaiHYOZS1AY2xEVCXZYgcgoI=";
          };
          doCheck = false;
          dontCheckRuntimeDeps = true; /* I only need Telegram for outbound notifications. This will probably break polling code. */
          propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
            super.certifi
            super.future
            super.urllib3
            super.tornado
            super.decorator
          ];
        });
      };
    };

    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"
    ] ++ srvConfig.components;

    config = {
      default_config = { };
      http = {
        server_host = "127.0.0.1";
        trusted_proxies = [ "127.0.0.1" ];
        use_x_forwarded_for = true;
      };
      homeassistant = {
        media_dirs.recordings = "/var/lib/hass/media/recordings";
        time_zone = config.time.timeZone;
        name = "Home";
      };
      inherit (srvConfig) telegram_bot notify;
    };
  };
  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0755 ${homeassistantUser} ${homeassistantUser}"
  ];

  /* Additional config */
  imports = [
    ./automations.nix
    ./scripts.nix
  ];
}
