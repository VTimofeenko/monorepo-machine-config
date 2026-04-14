{ pkgs, ... }:
{
  imports = [ ./non-functional/ssl.nix ]; # MQTT manages own SSL

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        # TODO: implement ACLs based on something other than VPN network rules
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  environment.systemPackages = [ pkgs.mqttui ];
}
