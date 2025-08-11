/**
  Simple esphome service config. Service authentication is to be done through
  an SSH tunnel.

  Some notes:

  - When just deployed – all installs were failing because `g++` binary
    downloaded by esphome was not executable. I fixed it by `chown` everything
    in `/var/lib/private/esphome` to `esphome:esphome`
*/
{ lib, config, ... }:
{
  services.home-assistant.extraComponents = [ "esphome" ];

  services.esphome = {
    enable = true;
    allowedDevices = [
      "/dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0"
      "/dev/serial/by-id/usb-Espressif_USB_JTAG_serial_debug_unit_7C:2C:67:42:CD:C8-if00"
      "/dev/serial/by-id/usb-1a86_USB_Single_Serial_58FA096927-if00"
    ];
  };

  systemd.services.esphome =
    let
      inherit (lib) mkForce;

      cfg = config.services.esphome;
      stateDir = "/var/lib/private/esphome";
      esphomeParams =
        if cfg.enableUnixSocket then
          "--socket /run/esphome/esphome.sock"
        else
          "--address ${cfg.address} --port ${toString cfg.port}";
    in
    {
      environment.PLATFORMIO_CORE_DIR = mkForce "/var/lib/private/esphome/.platformio";

      serviceConfig = {
        ExecStart = mkForce "${cfg.package}/bin/esphome dashboard ${esphomeParams} ${stateDir}";
        WorkingDirectory = mkForce stateDir;
      };
    };

}
