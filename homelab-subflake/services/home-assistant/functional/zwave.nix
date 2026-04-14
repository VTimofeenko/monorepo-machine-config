{
  config,
  ...
}:
{

  services.zwave-js = {
    enable = true;
    serialPort = "/dev/serial/by-id/usb-Silicon_Labs_HubZ_Smart_Home_Controller_516009E5-if00-port0";
    secretsConfigFile = config.age.secrets.zwave-secret.path;
  };
  # /* Sets up the rules for the USB dongle */
  # services.udev.extraRules = ''
  #   KERNEL=="ttyUSB[0-9]*",MODE="0666"
  # '';
}
