{ config, lib, ... }:
let
  printerName = "prusa-printer";
  credentialId = "prusa-printer-password";
in
{
  services.prometheus.exporters.prusa_exporter = {
    enable = true;
    port = 10009;
    openUdpFirewall = true; # Prusa Core One does not expose chamber state in PrusaLink: https://github.com/prusa3d/Prusa-Firmware-Buddy/issues/4459

    settings.printers = [
      {
        address = (lib.homelab.getHostInNetwork printerName "lan").fqdn;
        username = "maker";
        name = printerName;
        type = "Core One";
      }
    ];

    # Maps printer name → Systemd credential ID; password is kept out of the Nix store
    printerPasswords.${printerName} = credentialId;
  };

  systemd.services.prometheus-prusa-exporter.serviceConfig.LoadCredential = [
    "${credentialId}:${config.age.secrets."prusa-printer-password".path}"
  ];
}
