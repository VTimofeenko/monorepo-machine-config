# File that contains home-assistant scripts

{ config, ... }:
let
  inherit (config) my-data;
  srvConfig = my-data.lib.getServiceConfig "home-assistant";
in
{
  services.home-assistant.config.script = {
    night_nix = {
      alias = "Night";
      icon = "mdi:lightbulb-night";
      mode = "single";
      sequence = [
        {
          data.temperature = 71;
          service = "climate.set_temperature";
          target.entity_id = "climate.t6_pro_z_wave_programmable_thermostat";
        }
        {
          service = "switch.turn_off";
          target.entity_id = "switch.tp_link_smart_plug_8c5f_kasa_smart_plug_8c5f_1";
        }
      ];
    };
  } // srvConfig.scripts;
}
