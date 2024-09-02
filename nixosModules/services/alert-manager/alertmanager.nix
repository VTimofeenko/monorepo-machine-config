{ lib, config, ... }:
let
  srvName = "alert-manager";
  inherit (lib.homelab) getServiceIP getSettings getSrvSecret;
in
{
  age.secrets.alertmanager-tg-key.file = getSrvSecret srvName "telegram-key";
  systemd.services.alertmanager.serviceConfig = {
    LoadCredential = [ "tg-key:${config.age.secrets.alertmanager-tg-key.path}" ];
    Environment = [ "TG_KEY_PATH=%d/tg-key" ];
  };

  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = getServiceIP srvName;
    configuration = {
      route = {
        group_wait = "10s";
        group_interval = "30s";
        repeat_interval = "1h";
        receiver = "telegram";
      };
      receivers = [
        {
          name = "telegram";
          telegram_configs = [
            {
              send_resolved = true;
              bot_token_file = "\${TG_KEY_PATH}";
              chat_id = getSettings.Telegram.Vladimir;
            }
          ];
        }
      ];
    };
  };
}
