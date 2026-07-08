{ ... }:
{
  services.esphome = {
    enable = true;
    allowedDevices = [
      "/dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0"
      "/dev/serial/by-id/usb-Espressif_USB_JTAG_serial_debug_unit_7C:2C:67:42:CD:C8-if00"
      "/dev/serial/by-id/usb-1a86_USB_Single_Serial_58FA096927-if00"
    ];
  };
}
