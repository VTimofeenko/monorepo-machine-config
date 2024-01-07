/* File that contains home-assistant automations  */
{ config, ... }:
let
  inherit (config) my-data;
  srvConfig = my-data.lib.getServiceConfig "home-assistant";

  cfg = config.services.home-assistant;
in
{
  services.home-assistant.config = {
    "automation nix " = [
      {
        id = "test-record";
        alias = "Test doorbell recording";
        action = [{
          data = {
            duration = 30;
            lookback = 0;

            # W/A from https://github.com/home-assistant/core/issues/40241#issuecomment-1233073391
            filename = ''${cfg.config.homeassistant.media_dirs.recordings}/{{ '{{ entity_id.entity_id }}' }}_{{ now().strftime("%Y%m%d-%H%M%S") }}.mp4'';
          };
          service = "camera.record";
          target.entity_id = "camera.doorbell_sub";
        }];
        condition = [ ];
        description = "Test automation";
        mode = "single";
        trigger = [{ device_id = "7032626a1882aa058befd41a7651d112"; domain = "binary_sensor"; entity_id = "733390b58710bba2b4a18503f0f68936"; platform = "device"; type = "motion"; }]; # TODO: replace deviceId with proper name
      }
      {
        id = "day-temp";
        alias = "Day temp";
        description = "Set target temperature to 71 at 7 AM";

        trigger = [{ platform = "time"; at = "07:00"; }];
        action = [{ data.temperature = 71; service = "climate.set_temperature"; target.entity_id = "climate.t6_pro_z_wave_programmable_thermostat"; }];
        mode = "single";
      }
      {
        id = "sunset";
        alias = "Sunset";
        description = "Run light-related automations based on sunset";

        trigger = [{ platform = "sun"; event = "sunset"; offset = 0; }];
        action = [{ service = "switch.turn_on"; target.entity_id = "switch.tp_link_smart_plug_8c5f_kasa_smart_plug_8c5f_1"; }];

        mode = "single";
      }
    ] ++ srvConfig.automations;
    /* This allows automations to be provisioned from Nix and to be defined from UI */
    "automation ui" = "!include automations.yaml";
  };
}
