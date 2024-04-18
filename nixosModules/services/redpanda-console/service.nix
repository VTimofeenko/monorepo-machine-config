/**
  Module that ocnfigures redpanda-console the systemd service.
*/
{
  config,
  lib,
  redpanda-flake,
  pkgs,
  ...
}:
let
  redpanda-flake-packages' = redpanda-flake.packages.${pkgs.system};
in
{
  imports = [ redpanda-flake.nixosModules.redpanda-console ];

  # Source: https://github.com/fornybar/redpanda.nix/blob/main/modules/redpanda-console.nix
  services.redpanda-console = {
    enable = true;
    package = redpanda-flake-packages'.redpanda-console-bin;
    openPorts = lib.mkForce false; # Not accessed directly
    kafkaBrokers = config.services.redpanda.broker.settings.redpanda.kafka_api;
  };
}
