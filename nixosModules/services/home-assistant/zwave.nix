{
  config,
  lib,
  pkgs,
  ...
}:
let
  srvName = "home-assistant";
  inherit (lib.homelab) getSrvSecret;

  # FIXME: drop once https://github.com/NixOS/nixpkgs/pull/323350 is merged
  zwave136 = pkgs.callPackage ./zwave-pkg.nix { };

in
{
  age.secrets.zwaveSecrets = {
    file = getSrvSecret srvName "zwave-secrets";
    mode = "444";
    # owner = head (split ":" config.systemd.services.zwave-js.serviceConfig.User); # User is 'zwave-js:0'
    # owner = config.systemd.services.zwave-js.serviceConfig.User; # User is 'zwave-js:0'
    # group = config.systemd.services.zwave-js.serviceConfig.User; # User is 'zwave-js:0'
  };

  services.zwave-js = {
    enable = true;
    serialPort = "/dev/ttyUSB0";
    secretsConfigFile = config.age.secrets.zwaveSecrets.path;
    package = zwave136;
  };
  # /* Sets up the rules for the USB dongle */
  # services.udev.extraRules = ''
  #   KERNEL=="ttyUSB[0-9]*",MODE="0666"
  # '';
}
