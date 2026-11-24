{ lib, ... }:
let
  defaultReceiver = "telegram";
  # When the gateway is down nothing can be delivered anyway (no internet), and every other
  # alert is a consequence. Inhibiting them keeps the queue from flushing a storm on recovery.
  gatewayResource = "host:${lib.homelab.getServiceHost "gateway"}";
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
          group_by = [ "resource" ];
          group_wait = "30s";
          group_interval = "1m";
          repeat_interval = "4h";
          receiver = defaultReceiver;
        };
        inhibit_rules = [
          {
            source_matchers = [
              ''alertname="HostDown"''
              ''resource="${gatewayResource}"''
            ];
            target_matchers = [ ''resource!="${gatewayResource}"'' ];
          }
        ];
      }
    ]
    ++ (receiverConfigs |> builtins.attrValues)
  );
}
