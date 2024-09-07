# NixOS module that configures the UPS monitoring daemon
_:
# TODO:
# 1. Listen on monitoring network IP
{
  power.ups = {
    enable = true;
    ups.CP1500PFCRM2U = {
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        "vendorid = 0764" # Result from `lsusb`
        "productid = 0601" # Result from `lsusb`
      ];
      description = "Main rack UPS";
    };

    upsmon.monitor.CP1500PFCRM2U = {
      user = "upsmon";
    };

  };
  # TODO:
  # imports = [./webgui.nix];
}
