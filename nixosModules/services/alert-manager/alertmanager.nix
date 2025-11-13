{ lib, ... }:
let
  defaultReceiver = "telegram";
  receiverConfigs = {
    ntfy = import ./alertmanager-config/ntfy.nix {
      rcvName = "ntfy";
      address = "127.0.0.1:8000";
    };
    telegram = import ./alertmanager-config/telegram.nix {
      rcvName = defaultReceiver;
      chat_id = lib.homelab.getSettings.Telegram.Vladimir;
    };
  };
in
{
  services.prometheus.alertmanager.enable = true;

  imports = lib.localLib.mkImportsFromDir ./functional;

  # Looks like there is some bug with merging the `services.prometheus.alertmanager.config`...
  # Merging by hand:
  services.prometheus.alertmanager.configuration = lib.localLib.recursiveMerge (
    [
      {
        route = {
          group_wait = "10s";
          group_interval = "30s";
          repeat_interval = "4h";
          receiver = defaultReceiver;
        };
      }
    ]
    ++ (receiverConfigs |> builtins.attrValues)
  );
}
