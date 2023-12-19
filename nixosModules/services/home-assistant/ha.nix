{ config, ... }:
let
  inherit (config) my-data;
  srvConfig = my-data.lib.getServiceConfig "home-assistant";
in
{
  services.home-assistant = {
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
      ];
      "automation ui" = "!include automations.yaml";
    };
  };
  systemd.tmpfiles.rules =
    let
      homeassistantUser = config.systemd.services.home-assistant.serviceConfig.User;
    in
    [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0755 ${homeassistantUser} ${homeassistantUser}"
      "d ${config.services.home-assistant.config.homeassistant.media_dirs.recordings} 0755 ${homeassistantUser} ${homeassistantUser}"
    ];
}
