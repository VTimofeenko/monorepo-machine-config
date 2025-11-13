/**
  Sets up Telegram bot integration for Alert manager.
*/
{ lib, config, ... }:
let
  srvName = "alert-manager";
  inherit (lib.homelab) getSrvSecret;
in
{
  age.secrets.alertmanager-tg-key.file = getSrvSecret srvName "telegram-key";
  # Use the secret as a credential
  systemd.services.alertmanager.serviceConfig = {
    LoadCredential = [ "tg-key:${config.age.secrets.alertmanager-tg-key.path}" ];
    Environment = [ "TG_KEY_PATH=%d/tg-key" ];
  };
}
