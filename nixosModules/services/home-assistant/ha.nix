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
          propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
            super.certifi
            super.future
            super.urllib3
            super.tornado
            super.decorator
            super.APScheduler
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

    config = rec {
      default_config = { };
      http = {
        server_host = "127.0.0.1";
        trusted_proxies = [ "127.0.0.1" ];
        use_x_forwarded_for = true;
      };
      homeassistant = {
        media_dirs.recordings = "/var/lib/hass/media/recordings";
      };
      script = {
        night_nix = {
          alias = "Night";
          icon = "mdi:lightbulb-night";
          mode = "single";
          sequence = [
            { data.temperature = 71; service = "climate.set_temperature"; target.entity_id = "climate.t6_pro_z_wave_programmable_thermostat"; }
            { service = "switch.turn_off"; target.entity_id = "switch.tp_link_smart_plug_8c5f_kasa_smart_plug_8c5f_1"; }
          ];
        };
      };
      /* This allows automations to be provisioned from Nix and to be defined from UI */
      "automation nix " = [
        {
          id = "test-record";
          alias = "Test doorbell recording";
          action = [{
            data = {
              duration = 30;
              lookback = 0;

              # W/A from https://github.com/home-assistant/core/issues/40241#issuecomment-1233073391
              filename = ''${homeassistant.media_dirs.recordings}/{{ '{{ entity_id.entity_id }}' }}_{{ now().strftime("%Y%m%d-%H%M%S") }}.mp4'';
            };
            service = "camera.record";
            target.entity_id = "camera.doorbell_sub";
          }];
          condition = [ ];
          description = "Test automation";
          mode = "single";
          trigger = [{ device_id = "7032626a1882aa058befd41a7651d112"; domain = "binary_sensor"; entity_id = "733390b58710bba2b4a18503f0f68936"; platform = "device"; type = "motion"; }];
        }
      ] ++ srvConfig.automations;
      "automation ui" = "!include automations.yaml";
      inherit (srvConfig) telegram_bot notify;
    };
  };
  systemd.tmpfiles.rules =
    [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0755 ${homeassistantUser} ${homeassistantUser}"
      "d ${config.services.home-assistant.config.homeassistant.media_dirs.recordings} 0755 ${homeassistantUser} ${homeassistantUser}"
    ];
}
