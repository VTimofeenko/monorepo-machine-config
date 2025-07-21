/**
  Simple esphome service config. Service authentication is to be done through
  an SSH tunnel.

  Some notes:

  - When just deployed – all installs were failing because `g++` binary
    downloaded by esphome was not executable. I fixed it by `chown` everything
    in `/var/lib/private/esphome` to `esphome:esphome`
*/
{
  services.home-assistant.extraComponents = [ "esphome" ];

  services.esphome = {
    enable = true;
    allowedDevices = [
      "/dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0"
    ];
  };
}
