/**
  Sets up Telegram bot integration for Alert manager.
*/
{ config, ... }:
let
  srvName = "alert-manager";
in
{
  # Use the secret as a credential
  systemd.services.alertmanager.serviceConfig = {
    LoadCredential = [ "tg-key:${config.age.secrets."${srvName}-telegram-bot-key".path}" ];
    Environment = [ "TG_KEY_PATH=%d/tg-key" ];
  };
}
