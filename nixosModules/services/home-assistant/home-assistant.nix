{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.homelab) getServiceConfig getSrvSecret;

  srvName = "home-assistant";
  srvConfig = getServiceConfig srvName;

  homeassistantUser = config.systemd.services.home-assistant.serviceConfig.User;

in
{
  # Secrets
  age.secrets.ha-secret = {
    file = getSrvSecret srvName "ha-secrets";
    owner = homeassistantUser;
    path = "${config.services.home-assistant.configDir}/secrets.yaml";
  };

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "isal"
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"
      "homekit_controller"
      "zeroconf"
      "mqtt"
      "dhcp"
      "zha"
      "wiz"
    ] ++ srvConfig.components;

    # Build custom components. { } does not pass deps which is OK for now
    customComponents = map (x: pkgs.callPackage x { }) [ ./customComponents/meross_lan.nix ];

    config = {
      default_config = { };
      homeassistant = {
        media_dirs.recordings = "/var/lib/hass/media/recordings";
        time_zone = config.time.timeZone;
        name = "Home";
      };
      inherit (srvConfig) telegram_bot notify;
    };
  };

  # Additional config
  imports = lib.localLib.mkImportsFromDir ./functional;
}
