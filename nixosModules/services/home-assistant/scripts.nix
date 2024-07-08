# File that contains home-assistant scripts

{ config, ... }:
let
  inherit (config) my-data;
  srvConfig = my-data.lib.getServiceConfig "home-assistant";
in
{
  services.home-assistant.config.script = srvConfig.scripts;
}
