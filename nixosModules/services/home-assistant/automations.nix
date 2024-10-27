# File that contains home-assistant automations
{ config, ... }:
let
  cfg = config.services.home-assistant;
in
{
  services.home-assistant.config = {
    # "automation" needs to be first here
    "automation nix " = [
      {
        id = "test-record";
        alias = "Test doorbell recording";
        action = [
          {
            data = {
              duration = 30;
              lookback = 0;
              # W/A from https://github.com/home-assistant/core/issues/40241#issuecomment-1233073391
              filename = ''${cfg.config.homeassistant.media_dirs.recordings}/{{ '{{ entity_id.entity_id }}' }}_{{ now().strftime("%Y%m%d-%H%M%S") }}.mp4'';
            };
            service = "camera.record";
            target.entity_id = "camera.doorbell_sub";
          }
        ];
        condition = [ ];
        description = "Test automation";
        mode = "single";
        trigger = [
          {
            device_id = "7032626a1882aa058befd41a7651d112";
            domain = "binary_sensor";
            entity_id = "733390b58710bba2b4a18503f0f68936";
            platform = "device";
            type = "motion";
          }
        ];
      }

      {
        id = "day-routine";
        alias = "Day routine";
        description = "Actions to be processed at start of day";
        trigger = [
          {
            platform = "time";
            at = "07:00";
          }
        ];
        action = [
          {
            service = "script.day_mode";
            data = { };
          }
        ];
        mode = "single";
      }

      {
        id = "night-routine";
        alias = "Night routine";
        description = "Actions to be processed at night";
        trigger = [
          {
            platform = "time";
            at = "23:00:00";
          }
        ];
        action = [
          {
            service = "script.night_mode";
            data = { };
          }
          {
            service = "script.send_night_notification";
            data = { };
          }
        ];
        mode = "single";
      }

    ];
  };
}
