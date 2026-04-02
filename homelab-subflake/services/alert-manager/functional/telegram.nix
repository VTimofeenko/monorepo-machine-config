/**
  Sets up Telegram bot integration for Alert manager.
*/
{ config, ... }:
{
  # Use the secret as a credential
  systemd.services.alertmanager.serviceConfig = {
    LoadCredential = [ "tg-key:${config.age.secrets.telegram-bot-key-vt-s-bot.path}" ];
    Environment = [ "TG_KEY_PATH=%d/tg-key" ];
  };
}
