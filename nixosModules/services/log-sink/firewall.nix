{ config, lib, ... }:
{
  networking.firewall.interfaces.logging.allowedTCPPorts = lib.catAttrs "port" config.services.redpanda.broker.settings.redpanda.kafka_api;
}
