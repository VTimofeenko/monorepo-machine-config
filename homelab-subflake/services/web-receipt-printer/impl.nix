{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.web-receipt-printer;
in
{
  options.services.web-receipt-printer = {
    enable = mkEnableOption "Web Receipt Printer Service";

    package = mkOption {
      type = types.package;
      description = "The package to use.";
      default = (
        (pkgs.writers.writePython3Bin "webprinter" {
          libraries = [
            pkgs.python3Packages.flask
            pkgs.python3Packages.python-escpos
            pkgs.python3Packages.pyusb
            pkgs.python3Packages.pillow
          ];
          flakeIgnore = [ "E501" ];
        } ./source.py)
        |> (
          it:
          pkgs.runCommand "tinyprinter"
            {
              buildInputs = [ pkgs.makeWrapper ];
            }
            ''
              makeWrapper ${it}/bin/webprinter $out/bin/tinyprinter \
                --prefix LD_LIBRARY_PATH : ${pkgs.libusb1}/lib
            ''
        )
      );
    };

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port to bind the web server to.";
    };

    vendorId = mkOption {
      type = types.str;
      default = "04b8"; # Epson default
      description = "USB Vendor ID (lsusb) without 0x prefix";
    };

    productId = mkOption {
      type = types.str;
      default = "0202"; # `TM-T88IIIP` default
      description = "USB Product ID (lsusb) without 0x prefix";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.web-receipt-printer = {
      description = "Web Receipt Printer Interface";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        FLASK_RUN_PORT = toString cfg.port;
        VENDOR_ID = toString cfg.vendorId;
        PRODUCT_ID = toString cfg.productId;
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/tinyprinter";
        Restart = "always";
        RestartSec = "5s";

        DynamicUser = true;
        SupplementaryGroups = [
          "dialout"
        ];
        ProtectHome = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = "";
        SystemCallFilter = [ "@system-service" ];
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
      };
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="${cfg.vendorId}", ATTRS{idProduct}=="${cfg.productId}", MODE="0660", GROUP="dialout"
    '';
  };
}
