{ config, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${config.programs.niri.package}/bin/niri-session";
        user = "spacecadet";
      };
    };
  };
}
